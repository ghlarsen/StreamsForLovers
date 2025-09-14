# ⚡ Thunder Compute Setup Guide for AI Image Generation

Complete guide for setting up T4 GPU instance with ComfyUI for Your Japan Vibes custom image generation.

## 🎯 **Overview**

**What we're building:**
- T4 GPU instance (~$0.30-0.50/hour) 
- ComfyUI with custom SDXL models
- API integration for synchronized music + album art
- Your exact CivitAI style: WAI-NSFW-illustrious-SDXL + custom LORAs

**Cost Structure:**
- Setup: ~$1-2 (2-4 hours initial configuration)
- Per image: ~$0.0075-0.0125 (60-90 seconds generation)
- Monthly estimate: ~$5-10 for 500 images

## 🚀 **Step-by-Step Setup**

### **Phase 1: Create Thunder Compute Instance**

1. **Run the setup script:**
   ```bash
   ./scripts/setup_thunder_compute.sh
   ```

2. **Or create manually:**
   ```bash
   # Login if not already
   tnr login
   
   # Create instance interactively
   tnr create
   ```

3. **Select these options:**
   - Template: **ComfyUI – Advanced UI for Stable Diffusion**
   - GPU: **t4**
   - Mode: **prototyping**
   - vCPUs: **4** (default)
   - Disk: **100GB** (default)

4. **Get instance details:**
   ```bash
   tnr status
   ```
   Note your instance IP address!

### **Phase 2: Model Installation**

1. **Connect to instance:**
   ```bash
   tnr connect <your-instance-id>
   ```

2. **Set up model directories:**
   ```bash
   cd /workspace/ComfyUI/models
   mkdir -p checkpoints loras
   ```

3. **Download your custom models:**

   **Base Checkpoint (→ checkpoints/):**
   ```bash
   cd checkpoints
   # Get download URL from CivitAI - WAI-NSFW-illustrious-SDXL v15.0
   wget "YOUR_CIVITAI_DOWNLOAD_URL" -O "WAI-NSFW-illustrious-SDXL-v15.0.safetensors"
   ```

   **LORA Models (→ loras/):**
   ```bash
   cd ../loras
   
   # 薄塗り / USNR STYLE (thin painting style)
   wget "YOUR_THIN_PAINTING_LORA_URL" -O "thin_painting_style.safetensors"
   
   # Pony: People's Works v4 (character consistency) 
   wget "YOUR_PONY_LORA_URL" -O "pony_anime_v4.safetensors"
   
   # GENESIS LyCORIS (quality enhancement)
   wget "YOUR_GENESIS_LYCORIS_URL" -O "genesis_quality.safetensors"
   ```

### **Phase 3: Test ComfyUI Interface**

1. **Access ComfyUI web interface:**
   ```
   http://YOUR_INSTANCE_IP:8188
   ```

2. **Load your checkpoint:**
   - Use "CheckpointLoaderSimple" node
   - Select: `WAI-NSFW-illustrious-SDXL-v15.0.safetensors`

3. **Add LORA nodes:**
   - Add "LoraLoader" nodes for each LORA
   - Set weights: thin_painting (0.2), pony_anime (0.4), genesis (0.4)

4. **Test generation:**
   - Prompt: `"cozy anime room, warm lighting, rain outside window, peaceful atmosphere"`
   - Negative: `"worst quality, low quality, blurry, deformed, text, watermark"`
   - Resolution: 832x1216
   - Steps: 24, CFG: 3, Sampler: Euler Ancestral

### **Phase 4: API Integration**

1. **Update local configuration:**
   ```bash
   # Create Thunder Compute config
   echo "THUNDER_INSTANCE_IP=YOUR_INSTANCE_IP" > config/thunder_compute.env
   echo "THUNDER_INSTANCE_PORT=8188" >> config/thunder_compute.env
   ```

2. **Test API client:**
   ```bash
   cd /Users/sebastianlarsen/Developer/Streams\ for\ Lovers
   python -c "
   import asyncio
   from src.thunder_image_client import ThunderComputeImageClient, YourJapanVibesImageGenerator
   
   async def test():
       async with ThunderComputeImageClient('YOUR_INSTANCE_IP') as client:
           generator = YourJapanVibesImageGenerator(client)
           
           # Test health check
           healthy = await client.health_check()
           print(f'Instance healthy: {healthy}')
           
           if healthy:
               # Test image generation
               result = await generator.generate_album_art(
                   'lo-fi city pop, cozy rainy cafe atmosphere',
                   {'time_of_day': 'evening', 'weather': 'rain', 'base_mood': 'cozy'}
               )
               
               if result:
                   print('✅ Image generation successful!')
                   with open('test_image.png', 'wb') as f:
                       f.write(result['image_data'])
               else:
                   print('❌ Image generation failed')
   
   asyncio.run(test())
   "
   ```

## 🔧 **Integration with Music System**

### **Add to environment configuration:**

**config/.env.dev:**
```bash
# Thunder Compute Image Generation
THUNDER_COMPUTE_ENABLED=true
THUNDER_INSTANCE_IP=your_instance_ip_here
THUNDER_INSTANCE_PORT=8188
THUNDER_API_TIMEOUT=300
```

**config/.env.prod:**
```bash
# Thunder Compute Image Generation - PRODUCTION
THUNDER_COMPUTE_ENABLED=true
THUNDER_INSTANCE_IP=your_instance_ip_here
THUNDER_INSTANCE_PORT=8188
THUNDER_API_TIMEOUT=180
```

### **Update main application:**

```python
# In src/simple_main.py or main application
from thunder_image_client import ThunderComputeImageClient, YourJapanVibesImageGenerator

class AIStreamApp:
    def __init__(self):
        # ... existing init ...
        
        # Initialize Thunder Compute if enabled
        if os.getenv('THUNDER_COMPUTE_ENABLED', 'false').lower() == 'true':
            self.thunder_client = ThunderComputeImageClient(
                instance_ip=os.getenv('THUNDER_INSTANCE_IP'),
                port=int(os.getenv('THUNDER_INSTANCE_PORT', '8188'))
            )
            self.image_generator = YourJapanVibesImageGenerator(self.thunder_client)
            logger.info("✅ Thunder Compute image generation enabled")
        else:
            self.thunder_client = None
            self.image_generator = None
            logger.info("⚠️  Thunder Compute image generation disabled")
    
    async def generate_content(self, music_prompt, mood_data):
        """Generate synchronized music + album art"""
        
        # Start both generation tasks in parallel
        tasks = []
        
        # Music generation (Suno API)
        music_task = asyncio.create_task(self.suno_client.generate(music_prompt))
        tasks.append(('music', music_task))
        
        # Image generation (Thunder Compute)
        if self.image_generator:
            image_task = asyncio.create_task(
                self.image_generator.generate_album_art(music_prompt, mood_data)
            )
            tasks.append(('image', image_task))
        
        # Wait for completion
        results = {}
        for name, task in tasks:
            try:
                results[name] = await task
                logger.info(f"✅ {name} generation completed")
            except Exception as e:
                logger.error(f"❌ {name} generation failed: {e}")
                results[name] = None
        
        return results
```

## 💰 **Cost Management**

### **Auto-shutdown for cost control:**

```bash
# Stop instance when not in use
tnr stop <instance-id>

# Start when needed
tnr start <instance-id>

# Check costs
tnr status  # Shows running time
```

### **Batch processing strategy:**
```python
async def generate_album_art_batch(prompts_and_moods):
    """Generate multiple images in one session for cost efficiency"""
    
    results = []
    async with ThunderComputeImageClient(instance_ip) as client:
        generator = YourJapanVibesImageGenerator(client)
        
        for music_prompt, mood_data in prompts_and_moods:
            result = await generator.generate_album_art(music_prompt, mood_data)
            results.append(result)
            
        # Instance automatically managed by context manager
    
    return results
```

## 🛠️ **Troubleshooting**

### **Common Issues:**

**1. ComfyUI not accessible:**
```bash
# Check if service is running on instance
curl http://YOUR_INSTANCE_IP:8188/system_stats

# If not running, connect to instance and restart
tnr connect <instance-id>
sudo systemctl restart comfyui
```

**2. Model loading errors:**
```bash
# Check model files exist and have correct permissions
ls -la /workspace/ComfyUI/models/checkpoints/
ls -la /workspace/ComfyUI/models/loras/

# Fix permissions if needed
chmod 644 /workspace/ComfyUI/models/**/*.safetensors
```

**3. Generation timeout:**
- T4 is slower than A100, expect 60-120 seconds per image
- Increase timeout in client configuration
- Consider reducing steps from 32 to 24 for faster generation

**4. Out of memory errors:**
```python
# Reduce resolution or batch size
request = ImageGenerationRequest(
    width=704,   # Reduced from 832
    height=1024, # Reduced from 1216
    steps=20     # Reduced from 24
)
```

## 📊 **Performance Expectations**

### **T4 Performance Metrics:**
```yaml
Generation Time (832x1216, 24 steps):
  - Simple prompt: 60-90 seconds
  - With 3 LORAs: 90-120 seconds
  - Complex scenes: 120-180 seconds

Memory Usage:
  - Base SDXL: ~6GB
  - With LORAs: ~7GB
  - Available: 16GB ✅ Comfortable headroom

Cost per Generation:
  - Average: ~$0.01 (90 seconds at $0.40/hour)
  - Daily budget (50 images): ~$0.50
  - Monthly estimate: ~$15
```

## 🎉 **Ready for Production!**

Once setup is complete, you'll have:

✅ **T4 GPU instance** with ComfyUI and your exact models  
✅ **API integration** for programmatic generation  
✅ **Your Japan Vibes style** perfectly replicated  
✅ **Cost-optimized** batch processing  
✅ **Synchronized generation** with music  

**Next:** Get YouTube API keys and launch Your Japan Vibes stream with custom album art! 🇯🇵🎵✨

---

## 🔗 **Quick Commands Reference**

```bash
# Instance management
tnr status                    # Check instance status
tnr start <instance-id>       # Start stopped instance  
tnr stop <instance-id>        # Stop running instance
tnr connect <instance-id>     # SSH to instance
tnr delete <instance-id>      # Delete instance (careful!)

# Test API
python src/thunder_image_client.py

# Check ComfyUI
curl http://YOUR_IP:8188/system_stats

# Generate test image
python -c "from src.thunder_image_client import *; asyncio.run(main())"
```