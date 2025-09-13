#!/usr/bin/env python3
"""
AI Music Streaming Platform - Simple Main Application for Initial Deployment
This is a simplified version that can run without all dependencies for testing
"""

import os
import sys
import time
import logging
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
config_dir = Path(__file__).parent.parent / 'config'
env_path = config_dir / '.env'
if env_path.exists():
    load_dotenv(env_path)
    print(f"✅ Loaded configuration from {env_path}")
else:
    print(f"⚠️  No configuration file found at {env_path}")

# Configure logging
log_level = os.getenv('LOG_LEVEL', 'INFO')
log_dir = Path('/opt/ai-music-stream/logs')
log_dir.mkdir(exist_ok=True, parents=True)

logging.basicConfig(
    level=getattr(logging, log_level),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(log_dir / 'app.log', mode='a')
    ]
)

logger = logging.getLogger(__name__)

class SimpleAIStreamApp:
    """Simplified AI Music Stream Application for initial deployment"""
    
    def __init__(self):
        self.environment = os.getenv('ENVIRONMENT', 'development')
        self.debug_mode = os.getenv('DEBUG_MODE', 'false').lower() == 'true'
        self.stream_title = os.getenv('STREAM_TITLE', 'AI Music Stream')
        self.port = 8081 if self.environment == 'development' else 8080
        
        logger.info(f"🎵 AI Music Stream starting...")
        logger.info(f"📺 Environment: {self.environment}")
        logger.info(f"📺 Stream: {self.stream_title}")
        logger.info(f"🚀 Port: {self.port}")
        logger.info(f"🐛 Debug: {self.debug_mode}")
        
        # Check configuration
        self._verify_config()
    
    def _verify_config(self):
        """Verify configuration and log status"""
        config_items = [
            ('SUNO_API_KEY', 'Suno API Key'),
            ('YOUTUBE_STREAM_KEY', 'YouTube Stream Key'),
            ('DAILY_BUDGET_USD', 'Daily Budget'),
            ('GENERATION_INTERVAL_MINUTES', 'Generation Interval'),
        ]
        
        logger.info("🔧 Configuration Check:")
        for env_var, description in config_items:
            value = os.getenv(env_var)
            if value:
                # Hide sensitive values
                if 'KEY' in env_var:
                    display_value = value[:10] + '...' if len(value) > 10 else '***'
                else:
                    display_value = value
                logger.info(f"  ✅ {description}: {display_value}")
            else:
                logger.warning(f"  ⚠️  {description}: Not configured")
        
        # Log budget information
        daily_budget = os.getenv('DAILY_BUDGET_USD', '0.00')
        max_generations = os.getenv('MAX_DAILY_GENERATIONS', '0')
        logger.info(f"💰 Budget Configuration:")
        logger.info(f"  💵 Daily Budget: ${daily_budget}")
        logger.info(f"  🎵 Max Generations: {max_generations}")
    
    def health_check(self):
        """Health check endpoint"""
        return {
            'status': 'healthy',
            'environment': self.environment,
            'debug_mode': self.debug_mode,
            'stream_title': self.stream_title,
            'port': self.port,
            'timestamp': int(time.time()),
            'uptime_seconds': int(time.time() - self.start_time) if hasattr(self, 'start_time') else 0
        }
    
    def run(self):
        """Main application loop - simplified version"""
        logger.info("🚀 Starting AI Music Stream application...")
        self.start_time = time.time()
        
        if self.debug_mode:
            logger.info("🧪 Running in DEBUG mode")
        
        try:
            generation_interval = int(os.getenv('GENERATION_INTERVAL_MINUTES', '120')) * 60
            health_check_interval = int(os.getenv('HEALTH_CHECK_INTERVAL', '300'))
            
            last_generation_time = 0
            last_health_check = 0
            iteration_count = 0
            
            logger.info(f"⚙️  Configuration:")
            logger.info(f"  🎵 Music generation every {generation_interval//60} minutes")
            logger.info(f"  💓 Health checks every {health_check_interval} seconds")
            
            while True:
                current_time = time.time()
                iteration_count += 1
                
                # Health check and status log
                if (current_time - last_health_check) >= health_check_interval:
                    health = self.health_check()
                    logger.info(f"💓 Health Check #{iteration_count//30}: {health['status']} "
                              f"(uptime: {health['uptime_seconds']//60}m)")
                    last_health_check = current_time
                
                # Simulated music generation cycle
                if (current_time - last_generation_time) >= generation_interval:
                    logger.info("🎵 Music generation cycle triggered")
                    
                    skip_generation = os.getenv('SKIP_MUSIC_GENERATION', 'false').lower() == 'true'
                    if skip_generation:
                        logger.info("⏭️  Music generation skipped (SKIP_MUSIC_GENERATION=true)")
                    else:
                        # Simulate music generation process
                        logger.info("🎼 [SIMULATION] Checking API limits...")
                        logger.info("🎼 [SIMULATION] Generating city pop music...")
                        logger.info("🎼 [SIMULATION] Processing audio...")
                        logger.info("🎼 [SIMULATION] Music generation completed")
                    
                    last_generation_time = current_time
                
                # Log iteration status every 10 cycles (100 seconds)
                if iteration_count % 10 == 0:
                    logger.debug(f"🔄 Iteration {iteration_count} - System running normally")
                
                # Sleep for 10 seconds before next iteration
                time.sleep(10)
                
        except KeyboardInterrupt:
            logger.info("🛑 Received interrupt signal - shutting down gracefully")
        except Exception as e:
            logger.error(f"❌ Fatal error in main loop: {e}")
            raise
        finally:
            uptime = int(time.time() - self.start_time) if hasattr(self, 'start_time') else 0
            logger.info(f"👋 AI Music Stream stopped (uptime: {uptime//60}m {uptime%60}s)")

def main():
    """Entry point"""
    print("🎵 AI Music Streaming Platform - Simple Version")
    print("=" * 50)
    
    try:
        app = SimpleAIStreamApp()
        app.run()
        
    except Exception as e:
        logger.error(f"❌ Failed to start application: {e}")
        print(f"❌ Failed to start application: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()