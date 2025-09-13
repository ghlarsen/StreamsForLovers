#!/usr/bin/env python3
"""
Suno API Client for Music Generation
Based on official SunoAPI.org documentation
"""

import asyncio
import aiohttp
import json
import logging
import os
import time
from datetime import datetime
from typing import Dict, List, Optional, Any

logger = logging.getLogger(__name__)

class SunoAPIClient:
    """Official Suno API client for music generation"""
    
    def __init__(self):
        self.api_key = os.getenv('SUNO_API_KEY')
        self.api_url = os.getenv('SUNO_API_URL', 'https://api.sunoapi.org/api/v1')
        self.timeout = int(os.getenv('SUNO_API_TIMEOUT', '60'))
        
        if not self.api_key:
            raise ValueError("SUNO_API_KEY environment variable is required")
        
        self.headers = {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json'
        }
        
        # Model selection based on stage and quality needs
        self.models = {
            'balanced': 'v3_5',      # Stage 1: Cost-effective, good quality
            'high_quality': 'v4',    # Stage 2+: Better audio quality
            'advanced': 'v4_5'       # Stage 3+: Premium quality
        }
        
        # Default to balanced model for Stage 1
        self.current_model = self.models['balanced']
        
        # City Pop specific prompt templates
        self.city_pop_templates = {
            'chill': [
                "Relaxing city pop with smooth bass and dreamy synths, perfect for studying",
                "Mellow lo-fi city pop with gentle guitar and soft vocals, nostalgic vibes",
                "Chill city pop instrumental with warm piano and ambient textures"
            ],
            'energetic': [
                "Upbeat city pop with funky bass and bright synths, retro energy",
                "Energetic city pop with driving drums and catchy melodies, 80s inspired",
                "Vibrant city pop with electric guitar and danceable rhythm"
            ],
            'romantic': [
                "Romantic city pop with smooth saxophone and gentle vocals, sunset vibes",
                "Dreamy city pop ballad with soft synths and heartfelt melody",
                "Intimate city pop with warm vocals and tender instrumental"
            ],
            'melancholic': [
                "Melancholic city pop with minor chords and reflective mood, rainy night",
                "Bittersweet city pop with emotional vocals and wistful melody",
                "Nostalgic city pop with gentle melancholy and urban atmosphere"
            ],
            'study': [
                "Focus-friendly city pop instrumental, minimal vocals, concentration vibes",
                "Study session city pop with repetitive, non-distracting melody",
                "Ambient city pop perfect for background work, gentle and flowing"
            ]
        }
        
        # Usage tracking for cost control
        self.daily_usage = {
            'generations': 0,
            'cost_estimate': 0.0,
            'last_reset': datetime.now().date()
        }
        
        self.cost_per_generation = 0.01  # $0.01 per song estimate
        self.daily_budget = float(os.getenv('DAILY_BUDGET_USD', '0.60'))
    
    async def initialize(self):
        """Initialize the Suno API client"""
        logger.info("🎵 Initializing Suno API Client...")
        
        try:
            # Test API connectivity
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    f"{self.api_url}/health",
                    headers=self.headers,
                    timeout=aiohttp.ClientTimeout(total=10)
                ) as response:
                    if response.status in [200, 404]:  # 404 might mean no health endpoint
                        logger.info("✅ Suno API connectivity confirmed")
                        return True
                    else:
                        logger.warning(f"⚠️ Suno API returned status {response.status}")
                        return True  # Continue anyway
        except Exception as e:
            logger.warning(f"⚠️ Suno API health check failed: {e}")
            return True  # Continue anyway for now
    
    def _reset_daily_usage_if_needed(self):
        """Reset usage counter if it's a new day"""
        today = datetime.now().date()
        if self.daily_usage['last_reset'] != today:
            self.daily_usage = {
                'generations': 0,
                'cost_estimate': 0.0,
                'last_reset': today
            }
            logger.info("📊 Daily usage counter reset")
    
    def _check_budget(self) -> bool:
        """Check if we're within daily budget"""
        self._reset_daily_usage_if_needed()
        return self.daily_usage['cost_estimate'] < self.daily_budget
    
    def _track_usage(self):
        """Track API usage for cost control"""
        self.daily_usage['generations'] += 1
        self.daily_usage['cost_estimate'] += self.cost_per_generation
        
        logger.info(f"💰 Daily usage: {self.daily_usage['generations']} generations, "
                   f"${self.daily_usage['cost_estimate']:.2f} estimated cost")
    
    async def generate_music(self, prompt: str, mood: str = 'chill', 
                           metadata: Optional[Dict] = None) -> Optional[Dict[str, Any]]:
        """Generate music using Suno API"""
        
        # Check budget before generation
        if not self._check_budget():
            logger.warning(f"💸 Daily budget exceeded (${self.daily_budget}), skipping generation")
            return None
        
        try:
            # Enhance prompt with city pop specific elements
            enhanced_prompt = self._enhance_city_pop_prompt(prompt, mood)
            
            logger.info(f"🎵 Generating music: {enhanced_prompt[:50]}...")
            
            payload = {
                'prompt': enhanced_prompt,
                'model_version': self.current_model,
                'make_instrumental': False,  # Allow vocals for city pop
                'wait_audio': True  # Wait for generation to complete
            }
            
            # Add optional parameters based on metadata
            if metadata:
                if 'duration' in metadata:
                    payload['duration'] = metadata['duration']
                if 'style' in metadata:
                    payload['style'] = metadata['style']
            
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.api_url}/generate",
                    headers=self.headers,
                    json=payload,
                    timeout=aiohttp.ClientTimeout(total=self.timeout)
                ) as response:
                    
                    if response.status == 200:
                        result = await response.json()
                        
                        # Track usage
                        self._track_usage()
                        
                        # Process the result
                        return await self._process_generation_result(result, enhanced_prompt, mood, metadata)
                    else:
                        error_text = await response.text()
                        logger.error(f"❌ Suno API error: {response.status} - {error_text}")
                        return None
                        
        except asyncio.TimeoutError:
            logger.error("⏰ Suno API timeout")
            return None
        except Exception as e:
            logger.error(f"❌ Error generating music: {e}")
            return None
    
    def _enhance_city_pop_prompt(self, base_prompt: str, mood: str) -> str:
        """Enhance prompt with city pop specific elements"""
        
        # Get mood-specific template
        if mood in self.city_pop_templates:
            templates = self.city_pop_templates[mood]
            mood_template = templates[0]  # Use first template for consistency
        else:
            mood_template = self.city_pop_templates['chill'][0]
        
        # Combine user prompt with city pop template
        if base_prompt.strip():
            enhanced = f"{mood_template}, {base_prompt}"
        else:
            enhanced = mood_template
        
        # Add technical specifications for city pop
        enhanced += ", city pop genre, retro aesthetic, high quality production"
        
        # Add time-based elements for variety
        hour = datetime.now().hour
        if 22 <= hour or hour < 6:
            enhanced += ", late night vibes, intimate atmosphere"
        elif 6 <= hour < 12:
            enhanced += ", morning energy, fresh start feeling"
        elif 12 <= hour < 18:
            enhanced += ", afternoon warmth, steady rhythm"
        else:
            enhanced += ", evening glow, winding down"
        
        return enhanced
    
    async def _process_generation_result(self, result: Dict, prompt: str, 
                                       mood: str, metadata: Optional[Dict]) -> Dict[str, Any]:
        """Process the generation result from Suno API"""
        
        try:
            # Extract audio URL and metadata
            audio_url = result.get('audio_url') or result.get('audio') or result.get('url')
            
            if not audio_url:
                logger.error("❌ No audio URL in Suno API response")
                return None
            
            # Download the audio file
            audio_filename = await self._download_audio(audio_url)
            
            if audio_filename:
                return {
                    'filename': audio_filename,
                    'title': result.get('title', f"City Pop {mood.title()} Track"),
                    'prompt': prompt,
                    'mood': mood,
                    'duration': result.get('duration', 180),  # Default 3 minutes
                    'model_version': self.current_model,
                    'created_at': datetime.now().isoformat(),
                    'suno_id': result.get('id'),
                    'metadata': metadata or {},
                    'genre': 'city_pop_anime',
                    'tags': result.get('tags', []),
                    'lyrics': result.get('lyric', '')
                }
            else:
                logger.error("❌ Failed to download generated audio")
                return None
                
        except Exception as e:
            logger.error(f"❌ Error processing generation result: {e}")
            return None
    
    async def _download_audio(self, audio_url: str) -> Optional[str]:
        """Download generated audio file"""
        try:
            # Generate unique filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"cityPop_{timestamp}.mp3"
            filepath = f"music/{filename}"
            
            # Ensure music directory exists
            os.makedirs('music', exist_ok=True)
            
            async with aiohttp.ClientSession() as session:
                async with session.get(audio_url) as response:
                    if response.status == 200:
                        with open(filepath, 'wb') as f:
                            async for chunk in response.content.iter_chunked(8192):
                                f.write(chunk)
                        
                        logger.info(f"✅ Audio downloaded: {filepath}")
                        return filepath
                    else:
                        logger.error(f"❌ Failed to download audio: {response.status}")
                        return None
                        
        except Exception as e:
            logger.error(f"❌ Error downloading audio: {e}")
            return None
    
    async def extend_music(self, existing_track: str, extension_prompt: str) -> Optional[Dict]:
        """Extend existing music track"""
        
        if not self._check_budget():
            logger.warning("💸 Daily budget exceeded, skipping extension")
            return None
        
        try:
            payload = {
                'audio_url': existing_track,
                'prompt': extension_prompt,
                'model_version': self.current_model
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.api_url}/generate/extend",
                    headers=self.headers,
                    json=payload,
                    timeout=aiohttp.ClientTimeout(total=self.timeout)
                ) as response:
                    
                    if response.status == 200:
                        result = await response.json()
                        self._track_usage()
                        return await self._process_generation_result(
                            result, extension_prompt, 'extended', {'type': 'extension'}
                        )
                    else:
                        error_text = await response.text()
                        logger.error(f"❌ Extension failed: {response.status} - {error_text}")
                        return None
                        
        except Exception as e:
            logger.error(f"❌ Error extending music: {e}")
            return None
    
    async def generate_batch(self, prompts: List[str], mood: str = 'chill') -> List[Dict]:
        """Generate multiple tracks in batch"""
        results = []
        
        for i, prompt in enumerate(prompts):
            if not self._check_budget():
                logger.warning(f"💸 Budget limit reached after {i} generations")
                break
            
            result = await self.generate_music(prompt, mood)
            if result:
                results.append(result)
            
            # Rate limiting - wait between generations
            if i < len(prompts) - 1:
                await asyncio.sleep(2)  # 2 second delay between generations
        
        return results
    
    def get_usage_stats(self) -> Dict[str, Any]:
        """Get current usage statistics"""
        self._reset_daily_usage_if_needed()
        
        budget_remaining = self.daily_budget - self.daily_usage['cost_estimate']
        generations_remaining = int(budget_remaining / self.cost_per_generation)
        
        return {
            'daily_generations': self.daily_usage['generations'],
            'daily_cost': self.daily_usage['cost_estimate'],
            'budget_remaining': budget_remaining,
            'generations_remaining': max(0, generations_remaining),
            'current_model': self.current_model
        }
    
    def set_model_quality(self, quality: str):
        """Set model quality (balanced, high_quality, advanced)"""
        if quality in self.models:
            self.current_model = self.models[quality]
            logger.info(f"🎵 Switched to {quality} model: {self.current_model}")
        else:
            logger.warning(f"⚠️ Unknown quality setting: {quality}")
    
    async def shutdown(self):
        """Gracefully shutdown the Suno API client"""
        logger.info("🔄 Shutting down Suno API Client...")
        
        # Log final usage stats
        stats = self.get_usage_stats()
        logger.info(f"📊 Final daily stats: {stats['daily_generations']} generations, "
                   f"${stats['daily_cost']:.2f} cost")
        
        logger.info("✅ Suno API Client shutdown complete")