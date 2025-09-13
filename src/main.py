#!/usr/bin/env python3
"""
Interactive AI Music Streaming System - Main Application
Orchestrates chat monitoring, music generation, and streaming
"""

import asyncio
import logging
import os
import signal
import sys
from datetime import datetime
from pathlib import Path

from chat_bot import YouTubeChatBot
from music_generator import SunoMusicGenerator
from queue_manager import MusicQueueManager
from obs_controller import OBSController
from prompt_generator import PromptGenerator

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/app.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class InteractiveStreamManager:
    """Main application manager for the interactive AI music stream"""
    
    def __init__(self):
        self.running = False
        self.components = {}
        
        # Initialize components
        self.chat_bot = YouTubeChatBot()
        self.music_generator = SunoMusicGenerator()
        self.queue_manager = MusicQueueManager()
        self.obs_controller = OBSController()
        self.prompt_generator = PromptGenerator()
        
        # Register components for graceful shutdown
        self.components = {
            'chat_bot': self.chat_bot,
            'music_generator': self.music_generator,
            'queue_manager': self.queue_manager,
            'obs_controller': self.obs_controller
        }
        
        # Setup signal handlers
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals gracefully"""
        logger.info(f"Received signal {signum}, initiating shutdown...")
        self.running = False
    
    async def initialize(self):
        """Initialize all components"""
        logger.info("🎵 Initializing Interactive AI Music Streaming System...")
        
        try:
            # Create necessary directories
            Path('music').mkdir(exist_ok=True)
            Path('logs').mkdir(exist_ok=True)
            Path('videos').mkdir(exist_ok=True)
            
            # Initialize components
            await self.chat_bot.initialize()
            await self.music_generator.initialize()
            await self.queue_manager.initialize()
            await self.obs_controller.initialize()
            
            logger.info("✅ All components initialized successfully")
            return True
            
        except Exception as e:
            logger.error(f"❌ Failed to initialize components: {e}")
            return False
    
    async def run(self):
        """Main application loop"""
        if not await self.initialize():
            return
        
        logger.info("🚀 Starting Interactive AI Music Stream...")
        self.running = True
        
        # Start background tasks
        tasks = [
            asyncio.create_task(self._chat_monitoring_loop()),
            asyncio.create_task(self._music_generation_loop()),
            asyncio.create_task(self._queue_management_loop()),
            asyncio.create_task(self._status_monitoring_loop())
        ]
        
        try:
            await asyncio.gather(*tasks)
        except asyncio.CancelledError:
            logger.info("Tasks cancelled, shutting down...")
        except Exception as e:
            logger.error(f"Unexpected error in main loop: {e}")
        finally:
            await self.shutdown()
    
    async def _chat_monitoring_loop(self):
        """Monitor YouTube chat for commands and interactions"""
        logger.info("🗨️ Starting chat monitoring loop...")
        
        while self.running:
            try:
                # Process chat messages
                messages = await self.chat_bot.get_recent_messages()
                
                for message in messages:
                    await self._process_chat_message(message)
                
                await asyncio.sleep(2)  # Check chat every 2 seconds
                
            except Exception as e:
                logger.error(f"Error in chat monitoring: {e}")
                await asyncio.sleep(5)
    
    async def _process_chat_message(self, message):
        """Process individual chat messages for commands"""
        text = message.get('text', '').strip()
        author = message.get('author', 'Unknown')
        
        if text.startswith('!'):
            command = text[1:].lower().split()
            
            if command[0] == 'generate' and len(command) > 1:
                # User requested specific music generation
                prompt_text = ' '.join(command[1:])
                prompt = self.prompt_generator.create_from_user_input(prompt_text, author)
                await self.queue_manager.add_user_request(prompt, author)
                logger.info(f"🎼 User {author} requested: {prompt_text}")
                
            elif command[0] == 'mood' and len(command) > 1:
                # User requested mood-based generation
                mood = ' '.join(command[1:])
                prompt = self.prompt_generator.create_mood_prompt(mood, author)
                await self.queue_manager.add_user_request(prompt, author)
                logger.info(f"😊 User {author} requested mood: {mood}")
                
            elif command[0] == 'vote' and len(command) > 1:
                # User voting on poll
                vote = command[1].upper()
                await self.queue_manager.process_vote(vote, author)
                logger.info(f"🗳️ User {author} voted: {vote}")
    
    async def _music_generation_loop(self):
        """Generate music based on queue requests"""
        logger.info("🎼 Starting music generation loop...")
        
        while self.running:
            try:
                # Get next generation request
                request = await self.queue_manager.get_next_generation_request()
                
                if request:
                    logger.info(f"🎵 Generating music: {request['prompt']}")
                    
                    # Generate music using Suno API
                    result = await self.music_generator.generate_music(
                        prompt=request['prompt'],
                        metadata=request
                    )
                    
                    if result:
                        # Add generated music to playback queue
                        await self.queue_manager.add_generated_music(result)
                        logger.info(f"✅ Music generated successfully: {result['filename']}")
                    else:
                        logger.error("❌ Music generation failed")
                
                await asyncio.sleep(10)  # Check for new requests every 10 seconds
                
            except Exception as e:
                logger.error(f"Error in music generation: {e}")
                await asyncio.sleep(30)
    
    async def _queue_management_loop(self):
        """Manage music playback queue and OBS control"""
        logger.info("📋 Starting queue management loop...")
        
        while self.running:
            try:
                # Check if current track is finished
                if await self.obs_controller.is_track_finished():
                    # Get next track from queue
                    next_track = await self.queue_manager.get_next_track()
                    
                    if next_track:
                        # Load track in OBS and start playing
                        await self.obs_controller.load_track(next_track)
                        logger.info(f"🎶 Now playing: {next_track['title']}")
                        
                        # Update stream overlay with track info
                        await self.obs_controller.update_track_info(next_track)
                
                await asyncio.sleep(5)  # Check playback status every 5 seconds
                
            except Exception as e:
                logger.error(f"Error in queue management: {e}")
                await asyncio.sleep(10)
    
    async def _status_monitoring_loop(self):
        """Monitor system status and health"""
        logger.info("📊 Starting status monitoring loop...")
        
        while self.running:
            try:
                # Log system status
                status = {
                    'queue_size': await self.queue_manager.get_queue_size(),
                    'generation_requests': await self.queue_manager.get_pending_requests(),
                    'stream_status': await self.obs_controller.get_stream_status(),
                    'uptime': datetime.now().isoformat()
                }
                
                logger.info(f"📈 Status: Queue={status['queue_size']}, "
                          f"Pending={status['generation_requests']}, "
                          f"Stream={status['stream_status']}")
                
                await asyncio.sleep(60)  # Status update every minute
                
            except Exception as e:
                logger.error(f"Error in status monitoring: {e}")
                await asyncio.sleep(60)
    
    async def shutdown(self):
        """Gracefully shutdown all components"""
        logger.info("🔄 Shutting down Interactive AI Music Stream...")
        
        for name, component in self.components.items():
            try:
                if hasattr(component, 'shutdown'):
                    await component.shutdown()
                    logger.info(f"✅ {name} shutdown complete")
            except Exception as e:
                logger.error(f"❌ Error shutting down {name}: {e}")
        
        logger.info("👋 Shutdown complete")

def main():
    """Application entry point"""
    # Check for required environment variables
    required_env = ['YOUTUBE_API_KEY', 'YOUTUBE_STREAM_KEY', 'SUNO_API_KEY']
    missing_env = [var for var in required_env if not os.getenv(var)]
    
    if missing_env:
        logger.error(f"❌ Missing required environment variables: {', '.join(missing_env)}")
        logger.error("Please check your config/.env file")
        sys.exit(1)
    
    # Create and run the stream manager
    stream_manager = InteractiveStreamManager()
    
    try:
        asyncio.run(stream_manager.run())
    except KeyboardInterrupt:
        logger.info("👋 Application stopped by user")
    except Exception as e:
        logger.error(f"💥 Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()