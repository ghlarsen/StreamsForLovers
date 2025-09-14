#!/usr/bin/env python3
"""
Thunder Compute Image Generation Client
Integrates with ComfyUI instance for custom SDXL image generation
"""

import os
import sys
import json
import time
import asyncio
import aiohttp
import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from pathlib import Path

logger = logging.getLogger(__name__)

@dataclass
class ImageGenerationRequest:
    """Image generation request parameters"""
    prompt: str
    negative_prompt: str
    width: int = 832
    height: int = 1216
    steps: int = 24  # Optimized for T4
    cfg_scale: float = 3.0
    sampler: str = "euler_ancestral"
    clip_skip: int = 2
    lora_weights: Dict[str, float] = None

class ThunderComputeImageClient:
    """Client for Thunder Compute ComfyUI image generation"""
    
    def __init__(self, instance_ip: str = None, port: int = 8188):
        """
        Initialize Thunder Compute client
        
        Args:
            instance_ip: IP address of Thunder Compute instance
            port: ComfyUI API port (default 8188)
        """
        self.instance_ip = instance_ip
        self.port = port
        self.base_url = f"http://{instance_ip}:{port}" if instance_ip else None
        self.session = None
        
        # Default LORA weights for your custom style
        self.default_lora_weights = {
            "thin_painting_style": 0.2,  # 薄塗り style
            "pony_anime_v4": 0.4,         # Character consistency
            "genesis_quality": 0.4        # Quality enhancement
        }
        
        # Safety negative prompts
        self.safety_negative = (
            "head out of frame, one-piece swimsuit, look away, blurry eyes, "
            "shiny, blurry face, blurry eyes, blurry, worst quality, low quality, "
            "displeasing, text, watermark, bad anatomy, text, artist name, "
            "signature, hearts, deformed hands, missing finger, shiny skin, "
            "nsfw, explicit, sexual, nude, violence, weapon, political"
        )
    
    async def __aenter__(self):
        """Async context manager entry"""
        self.session = aiohttp.ClientSession()
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        if self.session:
            await self.session.close()
    
    def create_workflow(self, request: ImageGenerationRequest) -> Dict[str, Any]:
        """
        Create ComfyUI workflow for image generation
        
        Args:
            request: Image generation parameters
            
        Returns:
            ComfyUI workflow dictionary
        """
        
        # Combine negative prompts
        full_negative = f"{request.negative_prompt}, {self.safety_negative}"
        
        # Merge LORA weights
        lora_weights = self.default_lora_weights.copy()
        if request.lora_weights:
            lora_weights.update(request.lora_weights)
        
        workflow = {
            "1": {
                "class_type": "CheckpointLoaderSimple",
                "inputs": {
                    "ckpt_name": "WAI-NSFW-illustrious-SDXL-v15.0.safetensors"
                }
            },
            "2": {
                "class_type": "CLIPTextEncode",
                "inputs": {
                    "text": request.prompt,
                    "clip": ["1", 1]
                }
            },
            "3": {
                "class_type": "CLIPTextEncode", 
                "inputs": {
                    "text": full_negative,
                    "clip": ["1", 1]
                }
            },
            "4": {
                "class_type": "EmptyLatentImage",
                "inputs": {
                    "width": request.width,
                    "height": request.height,
                    "batch_size": 1
                }
            },
            "5": {
                "class_type": "KSampler",
                "inputs": {
                    "seed": int(time.time()),  # Random seed
                    "steps": request.steps,
                    "cfg": request.cfg_scale,
                    "sampler_name": request.sampler,
                    "scheduler": "normal",
                    "denoise": 1.0,
                    "model": ["1", 0],
                    "positive": ["2", 0],
                    "negative": ["3", 0],
                    "latent_image": ["4", 0]
                }
            },
            "6": {
                "class_type": "VAEDecode",
                "inputs": {
                    "samples": ["5", 0],
                    "vae": ["1", 2]
                }
            },
            "7": {
                "class_type": "SaveImage",
                "inputs": {
                    "filename_prefix": "anime_album_art",
                    "images": ["6", 0]
                }
            }
        }
        
        # Add LORA loaders if weights specified
        node_id = 8
        for lora_name, weight in lora_weights.items():
            if weight > 0:
                workflow[str(node_id)] = {
                    "class_type": "LoraLoader",
                    "inputs": {
                        "model": ["1", 0],
                        "clip": ["1", 1],
                        "lora_name": f"{lora_name}.safetensors",
                        "strength_model": weight,
                        "strength_clip": weight
                    }
                }
                # Update references to use LORA-modified model
                workflow["5"]["inputs"]["model"] = [str(node_id), 0]
                workflow["2"]["inputs"]["clip"] = [str(node_id), 1]
                workflow["3"]["inputs"]["clip"] = [str(node_id), 1]
                node_id += 1
        
        return workflow
    
    async def generate_image(self, request: ImageGenerationRequest) -> Optional[Dict[str, Any]]:
        """
        Generate image using ComfyUI API
        
        Args:
            request: Image generation parameters
            
        Returns:
            Generated image data or None if failed
        """
        if not self.base_url:
            raise ValueError("Instance IP not configured. Set instance_ip in constructor.")
        
        if not self.session:
            raise ValueError("Client not initialized. Use async with ThunderComputeImageClient():")
        
        try:
            # Create workflow
            workflow = self.create_workflow(request)
            
            # Submit generation request
            logger.info(f"🎨 Submitting image generation request: {request.prompt[:50]}...")
            
            async with self.session.post(
                f"{self.base_url}/prompt",
                json={"prompt": workflow}
            ) as response:
                
                if response.status != 200:
                    logger.error(f"Failed to submit prompt: {response.status}")
                    return None
                
                result = await response.json()
                prompt_id = result.get("prompt_id")
                
                if not prompt_id:
                    logger.error("No prompt ID returned")
                    return None
            
            # Poll for completion
            logger.info(f"⏳ Waiting for generation completion (ID: {prompt_id})")
            image_data = await self._wait_for_completion(prompt_id)
            
            if image_data:
                logger.info("✅ Image generation completed successfully")
                return {
                    "prompt_id": prompt_id,
                    "prompt": request.prompt,
                    "image_data": image_data,
                    "parameters": request.__dict__
                }
            else:
                logger.error("❌ Image generation failed")
                return None
                
        except Exception as e:
            logger.error(f"Error generating image: {e}")
            return None
    
    async def _wait_for_completion(self, prompt_id: str, max_wait: int = 300) -> Optional[bytes]:
        """
        Wait for image generation completion
        
        Args:
            prompt_id: Generation request ID
            max_wait: Maximum wait time in seconds
            
        Returns:
            Image data bytes or None if failed/timeout
        """
        start_time = time.time()
        
        while (time.time() - start_time) < max_wait:
            try:
                # Check queue status
                async with self.session.get(f"{self.base_url}/queue") as response:
                    if response.status == 200:
                        queue_data = await response.json()
                        
                        # Check if our prompt is still in queue
                        queue_remaining = queue_data.get("queue_remaining", [])
                        if not any(item[1] == prompt_id for item in queue_remaining):
                            # Generation might be complete, check history
                            async with self.session.get(f"{self.base_url}/history") as hist_response:
                                if hist_response.status == 200:
                                    history = await hist_response.json()
                                    
                                    if prompt_id in history:
                                        outputs = history[prompt_id].get("outputs", {})
                                        
                                        # Find the saved image
                                        for node_outputs in outputs.values():
                                            if "images" in node_outputs:
                                                images = node_outputs["images"]
                                                if images:
                                                    image_info = images[0]
                                                    # Download the image
                                                    image_url = f"{self.base_url}/view"
                                                    params = {
                                                        "filename": image_info["filename"],
                                                        "subfolder": image_info.get("subfolder", ""),
                                                        "type": image_info.get("type", "output")
                                                    }
                                                    
                                                    async with self.session.get(image_url, params=params) as img_response:
                                                        if img_response.status == 200:
                                                            return await img_response.read()
                
                # Wait before next check
                await asyncio.sleep(2)
                
            except Exception as e:
                logger.error(f"Error checking generation status: {e}")
                await asyncio.sleep(5)
        
        logger.error(f"Generation timeout after {max_wait} seconds")
        return None
    
    async def health_check(self) -> bool:
        """
        Check if ComfyUI instance is healthy
        
        Returns:
            True if instance is responding
        """
        if not self.base_url:
            return False
        
        try:
            async with self.session.get(f"{self.base_url}/system_stats", timeout=10) as response:
                return response.status == 200
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return False

class YourJapanVibesImageGenerator:
    """High-level interface for Your Japan Vibes image generation"""
    
    def __init__(self, thunder_client: ThunderComputeImageClient):
        self.thunder_client = thunder_client
        
        # Your Japan Vibes style templates
        self.style_templates = {
            "cozy_room": "cozy anime room, warm lighting, {mood}, soft focus, lo-fi aesthetic",
            "city_scene": "anime city street, {time_of_day}, {weather}, neon lights, urban atmosphere",
            "cafe_interior": "anime cafe interior, {lighting}, comfortable seating, plants, {atmosphere}",
            "study_space": "anime study room, books, soft lighting, {mood}, peaceful environment"
        }
        
        # Environmental modifiers
        self.time_modifiers = {
            "dawn": "soft morning light, golden hour, gentle shadows",
            "day": "bright daylight, clear visibility, energetic atmosphere", 
            "dusk": "warm evening light, orange sky, cozy atmosphere",
            "night": "dim lighting, artificial lights, intimate atmosphere",
            "late_night": "minimal lighting, moonlight, contemplative mood"
        }
        
        self.weather_modifiers = {
            "clear": "clear sky, bright atmosphere",
            "rain": "rain on window, water droplets, atmospheric mood",
            "snow": "snow outside, winter atmosphere, cozy interior contrast",
            "cloudy": "overcast sky, soft diffused lighting",
            "storm": "dramatic weather outside, safe interior feeling"
        }
    
    def create_visual_prompt(self, music_prompt: str, mood_data: Dict[str, Any]) -> str:
        """
        Convert music prompt to visual prompt for Your Japan Vibes aesthetic
        
        Args:
            music_prompt: Original music generation prompt
            mood_data: Environmental and mood data
            
        Returns:
            Visual prompt for image generation
        """
        
        # Extract mood keywords from music prompt
        mood_keywords = []
        if "cozy" in music_prompt.lower(): mood_keywords.append("cozy")
        if "chill" in music_prompt.lower(): mood_keywords.append("relaxed")  
        if "energetic" in music_prompt.lower(): mood_keywords.append("vibrant")
        if "melancholic" in music_prompt.lower(): mood_keywords.append("contemplative")
        
        # Get environmental data
        time_of_day = mood_data.get("time_of_day", "evening")
        weather = mood_data.get("weather", "clear")
        base_mood = mood_data.get("base_mood", "peaceful")
        
        # Select appropriate style template
        if "cafe" in music_prompt.lower():
            base_template = self.style_templates["cafe_interior"]
        elif "study" in music_prompt.lower():
            base_template = self.style_templates["study_space"]
        elif "city" in music_prompt.lower():
            base_template = self.style_templates["city_scene"]
        else:
            base_template = self.style_templates["cozy_room"]
        
        # Build prompt
        mood_str = ", ".join(mood_keywords) if mood_keywords else base_mood
        lighting_mod = self.time_modifiers.get(time_of_day, "soft lighting")
        weather_mod = self.weather_modifiers.get(weather, "")
        
        visual_prompt = base_template.format(
            mood=mood_str,
            time_of_day=time_of_day, 
            weather=weather,
            lighting=lighting_mod,
            atmosphere=mood_str
        )
        
        if weather_mod:
            visual_prompt += f", {weather_mod}"
        
        # Add Your Japan Vibes signature elements
        visual_prompt += ", anime style, soft colors, peaceful atmosphere, high quality, detailed"
        
        return visual_prompt
    
    async def generate_album_art(self, music_prompt: str, mood_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Generate album art for Your Japan Vibes stream
        
        Args:
            music_prompt: Music generation prompt
            mood_data: Environmental and mood context
            
        Returns:
            Generated album art data
        """
        
        # Create visual prompt
        visual_prompt = self.create_visual_prompt(music_prompt, mood_data)
        
        # Create generation request
        request = ImageGenerationRequest(
            prompt=visual_prompt,
            negative_prompt="worst quality, low quality, blurry, deformed, text, watermark",
            width=832,
            height=1216,  # Vertical aspect for album covers
            steps=24,     # T4 optimized
            cfg_scale=3.0,
            sampler="euler_ancestral",
            clip_skip=2
        )
        
        logger.info(f"🎨 Generating Your Japan Vibes album art: {visual_prompt[:100]}...")
        
        # Generate image
        result = await self.thunder_client.generate_image(request)
        
        if result:
            result["visual_prompt"] = visual_prompt
            result["music_prompt"] = music_prompt
            result["mood_data"] = mood_data
        
        return result

# Example usage
async def main():
    """Example usage of Thunder Compute image generation"""
    
    # Initialize client (you'll need to set the actual instance IP)
    instance_ip = "your-thunder-instance-ip"  # Get from tnr status
    
    async with ThunderComputeImageClient(instance_ip) as client:
        
        # Initialize Your Japan Vibes generator
        japan_vibes = YourJapanVibesImageGenerator(client)
        
        # Check health
        if not await client.health_check():
            print("❌ Thunder Compute instance not available")
            return
        
        print("✅ Thunder Compute instance healthy")
        
        # Generate sample album art
        music_prompt = "lo-fi city pop, cozy rainy cafe atmosphere, 3AM vibes"
        mood_data = {
            "time_of_day": "late_night",
            "weather": "rain", 
            "base_mood": "contemplative"
        }
        
        result = await japan_vibes.generate_album_art(music_prompt, mood_data)
        
        if result:
            print(f"✅ Generated album art: {result['prompt']}")
            
            # Save image
            image_path = Path("generated_album_art.png")
            image_path.write_bytes(result["image_data"])
            print(f"💾 Saved to: {image_path}")
        else:
            print("❌ Failed to generate album art")

if __name__ == "__main__":
    asyncio.run(main())