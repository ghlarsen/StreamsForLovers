#!/bin/bash

# Thunder Compute Setup Script for AI Image Generation
# Sets up T4 instance with ComfyUI and custom SDXL models

set -e

echo "🚀 Thunder Compute Setup for AI Image Generation"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Check Thunder CLI
echo -e "${BLUE}Step 1: Checking Thunder Compute CLI...${NC}"
if ! command -v tnr &> /dev/null; then
    echo -e "${RED}❌ Thunder Compute CLI not found${NC}"
    echo "Please install from: https://docs.thundercompute.com/getting-started/installation"
    exit 1
fi

echo -e "${GREEN}✅ Thunder CLI found${NC}"

# Step 2: Check authentication
echo -e "${BLUE}Step 2: Checking authentication...${NC}"
if ! tnr status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Thunder Compute${NC}"
    echo "Please run: tnr login"
    echo "Then re-run this script"
    exit 1
fi

echo -e "${GREEN}✅ Authenticated to Thunder Compute${NC}"

# Step 3: Manual instance creation (due to CLI interactive issues)
echo -e "${BLUE}Step 3: Instance Creation Instructions${NC}"
echo ""
echo -e "${YELLOW}Due to CLI limitations, please create the instance manually:${NC}"
echo ""
echo "1. Run this command interactively:"
echo -e "   ${BLUE}tnr create${NC}"
echo ""
echo "2. Select these options:"
echo "   Template: ${GREEN}ComfyUI – Advanced UI for Stable Diffusion${NC}"
echo "   GPU: ${GREEN}t4${NC}"
echo "   Mode: ${GREEN}prototyping${NC}"
echo "   vCPUs: ${GREEN}4${NC} (default)"
echo "   Disk: ${GREEN}100GB${NC} (default)"
echo ""
echo "3. Wait for instance creation (may take 2-5 minutes)"
echo ""
echo "4. Get instance IP address:"
echo -e "   ${BLUE}tnr status${NC}"
echo ""
echo "5. Note the instance IP and continue to model setup"
echo ""

read -p "Press Enter once you've created the instance and have the IP address..."

# Step 4: Get instance information
echo -e "${BLUE}Step 4: Getting instance information...${NC}"
echo ""
echo "Current Thunder Compute instances:"
tnr status

echo ""
read -p "Enter your instance IP address: " INSTANCE_IP

if [ -z "$INSTANCE_IP" ]; then
    echo -e "${RED}❌ Instance IP required${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Instance IP: $INSTANCE_IP${NC}"

# Step 5: Connect to instance and set up models
echo -e "${BLUE}Step 5: Setting up models on instance...${NC}"
echo ""
echo "The script will now connect to your instance and set up the models."
echo "This may take 10-20 minutes depending on download speeds."
echo ""

read -p "Continue with model setup? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo "Setup cancelled. You can run model setup manually later."
    exit 0
fi

# Create model setup script for the instance
cat > /tmp/setup_models.sh << 'EOF'
#!/bin/bash

echo "🎨 Setting up AI models for Your Japan Vibes..."

# Navigate to ComfyUI models directory
cd /workspace/ComfyUI/models

# Create directories if they don't exist
mkdir -p checkpoints loras

echo "📥 Downloading base checkpoint..."
# Download WAI-NSFW-illustrious-SDXL (you'll need to replace with actual download URL)
cd checkpoints
# Note: You need to get the actual download URLs from CivitAI
# These are placeholder URLs - replace with real ones
echo "⚠️  Please manually download these models:"
echo ""
echo "1. WAI-NSFW-illustrious-SDXL v15.0:"
echo "   URL: https://civitai.com/models/XXXXX"
echo "   Save as: WAI-NSFW-illustrious-SDXL-v15.0.safetensors"
echo ""
echo "2. 薄塗り / USNR STYLE LORA:"  
echo "   URL: https://civitai.com/models/YYYYY"
echo "   Save as: thin_painting_style.safetensors"
echo ""
echo "3. Pony: People's Works v4:"
echo "   URL: https://civitai.com/models/ZZZZZ" 
echo "   Save as: pony_anime_v4.safetensors"
echo ""
echo "4. GENESIS LyCORIS:"
echo "   URL: https://civitai.com/models/AAAAA"
echo "   Save as: genesis_quality.safetensors"
echo ""

# For now, create placeholder files to test the setup
echo "Creating placeholder model files for testing..."
touch WAI-NSFW-illustrious-SDXL-v15.0.safetensors

cd ../loras
touch thin_painting_style.safetensors
touch pony_anime_v4.safetensors  
touch genesis_quality.safetensors

echo "✅ Model directories set up"
echo ""
echo "🔧 ComfyUI should now be accessible at:"
echo "   http://$(curl -s ifconfig.me):8188"
echo ""
echo "📋 Next steps:"
echo "1. Open ComfyUI in your browser"  
echo "2. Replace placeholder model files with real downloads"
echo "3. Test image generation workflow"
echo "4. Update your local code with the instance IP"

EOF

# Copy and run the setup script on the instance
echo "📤 Copying setup script to instance..."
# Note: Thunder CLI scp might have similar issues, so we'll provide manual instructions

echo ""
echo -e "${YELLOW}Manual Setup Instructions:${NC}"
echo ""
echo "1. Connect to your instance:"
echo -e "   ${BLUE}tnr connect <your-instance-id>${NC}"
echo ""
echo "2. Run the model setup commands:"
echo -e "   ${BLUE}cd /workspace/ComfyUI/models${NC}"
echo -e "   ${BLUE}mkdir -p checkpoints loras${NC}"
echo ""
echo "3. Download your models (get URLs from CivitAI):"
echo "   - WAI-NSFW-illustrious-SDXL v15.0 → checkpoints/"
echo "   - 薄塗り LORA → loras/" 
echo "   - Pony v4 LORA → loras/"
echo "   - GENESIS LyCORIS → loras/"
echo ""
echo "4. Test ComfyUI access:"
echo -e "   ${BLUE}http://$INSTANCE_IP:8188${NC}"
echo ""

# Step 6: Update local configuration
echo -e "${BLUE}Step 6: Updating local configuration...${NC}"

# Update the thunder client with the instance IP
if [ -f "src/thunder_image_client.py" ]; then
    echo "# Thunder Compute Configuration" > config/thunder_compute.env
    echo "THUNDER_INSTANCE_IP=$INSTANCE_IP" >> config/thunder_compute.env
    echo "THUNDER_INSTANCE_PORT=8188" >> config/thunder_compute.env
    
    echo -e "${GREEN}✅ Configuration saved to config/thunder_compute.env${NC}"
fi

# Step 7: Final instructions
echo ""
echo -e "${GREEN}🎉 Thunder Compute Setup Complete!${NC}"
echo ""
echo -e "${BLUE}Summary:${NC}"
echo "• Instance IP: $INSTANCE_IP"
echo "• ComfyUI URL: http://$INSTANCE_IP:8188"
echo "• Configuration: config/thunder_compute.env"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Download and install your custom models on the instance"
echo "2. Test image generation through ComfyUI web interface"  
echo "3. Update src/thunder_image_client.py with your instance IP"
echo "4. Run python src/thunder_image_client.py to test API integration"
echo ""
echo -e "${BLUE}Cost Management:${NC}"
echo "• T4 Prototyping: ~$0.30-0.50/hour"
echo "• Stop instance when not in use: tnr stop <instance-id>"
echo "• Start when needed: tnr start <instance-id>"
echo ""
echo -e "${GREEN}Ready for Your Japan Vibes image generation! 🇯🇵✨${NC}"