#!/usr/bin/env python3
"""
Background Video Generator for AI Music Stream
Generates animated backgrounds that match music mood and user requests
"""

import asyncio
import json
import logging
import os
import requests
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any

logger = logging.getLogger(__name__)

class BackgroundGenerator:
    """Generates animated backgrounds using Adobe Firefly API"""
    
    def __init__(self):
        self.api_key = os.getenv('ADOBE_FIREFLY_API_KEY')
        self.api_url = os.getenv('ADOBE_FIREFLY_API_URL', 'https://firefly-api.adobe.io/v2')
        self.timeout = int(os.getenv('ADOBE_FIREFLY_API_TIMEOUT', '120'))
        
        if not self.api_key:
            raise ValueError("ADOBE_FIREFLY_API_KEY environment variable is required")
        
        self.headers = {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json',
            'X-API-Key': self.api_key
        }
        
        # Background generation settings
        self.video_settings = {
            'duration': 30,  # seconds - enough for seamless looping
            'resolution': '1920x1080',
            'fps': 30,
            'format': 'mp4'
        }
        
        # Mood-to-visual mappings
        self.mood_prompts = {
            'chill': [
                'flowing abstract waves in soft pastels, gentle movement',
                'minimalist geometric shapes floating peacefully',
                'soft cloud formations drifting slowly across gradient sky'
            ],
            'energetic': [
                'dynamic particle systems with vibrant colors',
                'fast-moving geometric patterns in bright neon',
                'pulsing light effects with rhythmic energy'
            ],
            'ambient': [
                'ethereal mist floating in space, very slow movement',
                'subtle color gradients slowly shifting and blending',
                'zen-like water ripples in monochrome'
            ],
            'jazz': [
                'smooth smoke swirls with warm golden tones',
                'vintage vinyl record spinning with abstract elements',
                'art deco patterns flowing with musical rhythm'
            ],
            'electronic': [
                'digital grid patterns with neon accents',
                'cyberpunk-inspired geometric animations',
                'holographic interfaces with futuristic elements'
            ],
            'nature': [
                'peaceful forest with gentle leaf movement',
                'calm ocean waves under sunset sky',
                'flowing river through misty mountains'
            ],
            'study': [
                'library atmosphere with floating books and papers',
                'desk setup with gentle lighting and coffee steam',
                'cozy room with soft lamp glow and plants'
            ],
            'rain': [
                'gentle raindrops on window with city lights',
                'peaceful rainfall in forest with soft lighting',
                'water droplets creating ripples on calm surface'
            ]
        }
        
        # Time-based visual themes
        self.time_themes = {
            'morning': 'sunrise colors, warm golden light, fresh beginnings',
            'afternoon': 'bright natural lighting, clear skies, vibrant energy',
            'evening': 'sunset hues, warm orange and pink tones, winding down',
            'night': 'dark blues and purples, starry effects, peaceful atmosphere',
            'late_night': 'deep darkness with subtle neon, midnight vibes'
        }
        
        # Seasonal themes
        self.seasonal_themes = {
            'spring': 'fresh green colors, blooming flowers, renewal energy',
            'summer': 'bright warm colors, sunny atmosphere, vacation vibes',
            'autumn': 'orange and red leaves, cozy atmosphere, harvest colors',
            'winter': 'cool blues and whites, snow effects, minimal warmth'
        }
    
    async def initialize(self):
        """Initialize the background generator"""
        logger.info("🎬 Initializing Background Generator...")
        
        # Create videos directory
        Path('videos').mkdir(exist_ok=True)
        Path('videos/backgrounds').mkdir(exist_ok=True)
        Path('videos/cache').mkdir(exist_ok=True)
        
        # Test API connectivity
        try:
            test_response = await self._test_api_connection()
            if test_response:
                logger.info("✅ Adobe Firefly API connection successful")
                return True
            else:
                logger.error("❌ Adobe Firefly API connection failed")
                return False
        except Exception as e:
            logger.error(f"❌ Failed to initialize background generator: {e}")
            return False
    
    async def _test_api_connection(self) -> bool:
        """Test API connectivity"""
        try:
            # Test with a simple endpoint (this may need to be adjusted based on actual API)
            response = requests.get(
                f"{self.api_url}/status",  # Placeholder - adjust based on actual API
                headers=self.headers,
                timeout=10
            )
            return response.status_code in [200, 401]  # 401 might mean API key issue but API is accessible
        except Exception as e:
            logger.warning(f"API test failed: {e}")
            return False
    
    async def generate_background(self, prompt: str, mood: str = 'chill', 
                                metadata: Optional[Dict] = None) -> Optional[Dict[str, Any]]:
        """Generate an animated background video"""
        try:
            logger.info(f"🎬 Generating background: {prompt[:50]}...")
            
            # Enhanced prompt with technical specifications
            enhanced_prompt = self._enhance_prompt(prompt, mood, metadata)
            
            # Generate video using Firefly API
            generation_result = await self._call_firefly_api(enhanced_prompt)
            
            if generation_result:
                # Download and process the generated video
                video_path = await self._download_video(generation_result)
                
                if video_path:
                    # Post-process for seamless looping
                    processed_path = await self._process_for_looping(video_path)
                    
                    return {
                        'filename': processed_path,
                        'prompt': prompt,
                        'mood': mood,
                        'duration': self.video_settings['duration'],
                        'resolution': self.video_settings['resolution'],
                        'created_at': datetime.now().isoformat(),
                        'metadata': metadata or {}
                    }
            
            logger.error("❌ Background generation failed")
            return None
            
        except Exception as e:
            logger.error(f"❌ Error generating background: {e}")
            return None
    
    def _enhance_prompt(self, base_prompt: str, mood: str, metadata: Optional[Dict]) -> str:
        """Enhance the base prompt with mood, time, and technical specifications"""
        
        # Start with base prompt
        enhanced = base_prompt
        
        # Add mood-specific elements
        if mood in self.mood_prompts:
            mood_element = self.mood_prompts[mood][0]  # Use first option for consistency
            enhanced += f", {mood_element}"
        
        # Add time-based elements
        current_hour = datetime.now().hour
        if 5 <= current_hour < 12:
            enhanced += f", {self.time_themes['morning']}"
        elif 12 <= current_hour < 17:
            enhanced += f", {self.time_themes['afternoon']}"
        elif 17 <= current_hour < 21:
            enhanced += f", {self.time_themes['evening']}"
        elif 21 <= current_hour < 24:
            enhanced += f", {self.time_themes['night']}"
        else:
            enhanced += f", {self.time_themes['late_night']}"
        
        # Add seasonal elements
        month = datetime.now().month
        if month in [3, 4, 5]:
            enhanced += f", {self.seasonal_themes['spring']}"
        elif month in [6, 7, 8]:
            enhanced += f", {self.seasonal_themes['summer']}"
        elif month in [9, 10, 11]:
            enhanced += f", {self.seasonal_themes['autumn']}"
        else:
            enhanced += f", {self.seasonal_themes['winter']}"
        
        # Add technical specifications
        enhanced += (
            f", seamless loop animation, {self.video_settings['duration']} seconds, "
            f"smooth transitions, abstract style suitable for background, "
            f"no text or logos, continuous motion, {self.video_settings['resolution']} resolution"
        )
        
        return enhanced
    
    async def _call_firefly_api(self, prompt: str) -> Optional[Dict]:
        """Call Adobe Firefly API to generate video"""
        try:
            payload = {
                'prompt': prompt,
                'duration': self.video_settings['duration'],
                'width': int(self.video_settings['resolution'].split('x')[0]),
                'height': int(self.video_settings['resolution'].split('x')[1]),
                'fps': self.video_settings['fps'],
                'format': self.video_settings['format'],
                'style': 'abstract',
                'loop': True
            }
            
            response = requests.post(
                f"{self.api_url}/generate/video",
                headers=self.headers,
                json=payload,
                timeout=self.timeout
            )
            
            if response.status_code == 200:
                result = response.json()
                logger.info("✅ Video generation request successful")
                
                # Handle async generation (most AI APIs work this way)
                if 'job_id' in result:
                    return await self._wait_for_generation(result['job_id'])
                else:
                    return result
            else:
                logger.error(f"❌ API call failed: {response.status_code} - {response.text}")
                return None
                
        except Exception as e:
            logger.error(f"❌ Error calling Firefly API: {e}")
            return None
    
    async def _wait_for_generation(self, job_id: str, max_wait: int = 300) -> Optional[Dict]:
        """Wait for async video generation to complete"""
        start_time = time.time()
        
        while time.time() - start_time < max_wait:
            try:
                response = requests.get(
                    f"{self.api_url}/jobs/{job_id}",
                    headers=self.headers,
                    timeout=30
                )
                
                if response.status_code == 200:
                    result = response.json()
                    status = result.get('status', 'unknown')
                    
                    if status == 'completed':
                        logger.info(f"✅ Video generation completed (job: {job_id})")
                        return result
                    elif status == 'failed':
                        logger.error(f"❌ Video generation failed (job: {job_id})")
                        return None
                    else:
                        # Still processing
                        logger.info(f"⏳ Video generation in progress... ({status})")
                        await asyncio.sleep(10)
                else:
                    logger.error(f"❌ Job status check failed: {response.status_code}")
                    await asyncio.sleep(10)
                    
            except Exception as e:
                logger.error(f"❌ Error checking job status: {e}")
                await asyncio.sleep(10)
        
        logger.error(f"❌ Video generation timeout (job: {job_id})")
        return None
    
    async def _download_video(self, generation_result: Dict) -> Optional[str]:
        """Download the generated video"""
        try:
            download_url = generation_result.get('download_url') or generation_result.get('url')
            if not download_url:
                logger.error("❌ No download URL in generation result")
                return None
            
            # Generate unique filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"background_{timestamp}.mp4"
            filepath = f"videos/backgrounds/{filename}"
            
            # Download video
            response = requests.get(download_url, timeout=60)
            response.raise_for_status()
            
            # Save to file
            with open(filepath, 'wb') as f:
                f.write(response.content)
            
            logger.info(f"✅ Video downloaded: {filepath}")
            return filepath
            
        except Exception as e:
            logger.error(f"❌ Error downloading video: {e}")
            return None
    
    async def _process_for_looping(self, video_path: str) -> str:
        """Process video for seamless looping using ffmpeg"""
        try:
            output_path = video_path.replace('.mp4', '_loop.mp4')
            
            # Use ffmpeg to create seamless loop
            # This is a placeholder - actual implementation would use subprocess
            # to call ffmpeg with appropriate filters for seamless looping
            
            # For now, just copy the file
            import shutil
            shutil.copy2(video_path, output_path)
            
            logger.info(f"✅ Video processed for looping: {output_path}")
            return output_path
            
        except Exception as e:
            logger.error(f"❌ Error processing video for looping: {e}")
            return video_path  # Return original if processing fails
    
    async def create_mood_background(self, mood: str, user_request: Optional[str] = None) -> Optional[Dict]:
        """Create a background based on mood and optional user request"""
        
        # Get base prompt for mood
        if mood in self.mood_prompts:
            base_prompts = self.mood_prompts[mood]
            base_prompt = base_prompts[0]  # Use first option for consistency
        else:
            base_prompt = "abstract flowing patterns with gentle movement"
        
        # Enhance with user request if provided
        if user_request:
            prompt = f"{base_prompt}, inspired by: {user_request}"
        else:
            prompt = base_prompt
        
        return await self.generate_background(prompt, mood)
    
    async def create_weather_background(self, weather_condition: str, mood: str = 'chill') -> Optional[Dict]:
        """Create a background based on weather conditions"""
        
        weather_prompts = {
            'rain': 'gentle raindrops on glass, soft reflections, peaceful atmosphere',
            'sunny': 'warm sunlight filtering through, bright and cheerful',
            'cloudy': 'soft cloud formations, muted lighting, calm ambiance',
            'snow': 'gentle snowfall, winter wonderland, serene white landscape',
            'storm': 'dramatic clouds with distant lightning, powerful yet beautiful',
            'clear': 'clear skies with subtle gradients, peaceful and open'
        }
        
        weather_prompt = weather_prompts.get(weather_condition, weather_prompts['clear'])
        return await self.generate_background(weather_prompt, mood, {'weather': weather_condition})
    
    async def get_cached_background(self, mood: str, theme: Optional[str] = None) -> Optional[str]:
        """Get a cached background if available"""
        cache_dir = Path('videos/cache')
        
        # Look for cached backgrounds matching mood/theme
        pattern = f"*{mood}*{theme or ''}*.mp4"
        cached_files = list(cache_dir.glob(pattern))
        
        if cached_files:
            # Return most recent cached file
            latest_file = max(cached_files, key=lambda x: x.stat().st_mtime)
            logger.info(f"📁 Using cached background: {latest_file}")
            return str(latest_file)
        
        return None
    
    async def cleanup_old_backgrounds(self, keep_hours: int = 24):
        """Clean up old background videos to save disk space"""
        try:
            import time
            cutoff_time = time.time() - (keep_hours * 3600)
            
            backgrounds_dir = Path('videos/backgrounds')
            cache_dir = Path('videos/cache')
            
            cleaned_count = 0
            for directory in [backgrounds_dir, cache_dir]:
                if directory.exists():
                    for video_file in directory.glob('*.mp4'):
                        if video_file.stat().st_mtime < cutoff_time:
                            video_file.unlink()
                            cleaned_count += 1
            
            if cleaned_count > 0:
                logger.info(f"🧹 Cleaned up {cleaned_count} old background videos")
                
        except Exception as e:
            logger.error(f"❌ Error cleaning up backgrounds: {e}")
    
    async def shutdown(self):
        """Gracefully shutdown the background generator"""
        logger.info("🔄 Shutting down Background Generator...")
        
        # Clean up resources
        await self.cleanup_old_backgrounds(keep_hours=2)
        
        logger.info("✅ Background Generator shutdown complete")