# Deployment Commands for Server Setup

## Server Connection Details
- **IP Address**: 161.97.116.47
- **Username**: root
- **Password**: TommyLiveRobinson12
- **Location**: Hub Europe

## Step 1: Connect to Server
```bash
ssh root@161.97.116.47
# Enter password when prompted: TommyLiveRobinson12
```

## Step 2: Initial Server Setup
```bash
# Update system
apt update && apt upgrade -y

# Install essential packages
apt install -y curl wget git python3 python3-pip python3-venv nodejs npm ffmpeg xvfb pulseaudio alsa-utils software-properties-common

# Install OBS Studio
add-apt-repository ppa:obsproject/obs-studio -y
apt update
apt install -y obs-studio
```

## Step 3: Create Project Structure
```bash
# Create application directory
mkdir -p /opt/ai-music-stream
cd /opt/ai-music-stream

# Clone the project (you'll need to upload it first, for now create structure)
mkdir -p {src,config,logs,music,videos,scripts}

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install requests websocket-client python-dotenv asyncio aiohttp pytchat obs-websocket-py
```

## Step 4: Upload Project Files
You have several options:

### Option A: Git Repository (Recommended)
```bash
# If you create a GitHub repo
git clone https://github.com/yourusername/ai-music-stream.git /opt/ai-music-stream
cd /opt/ai-music-stream
source venv/bin/activate
pip install -r requirements.txt
```

### Option B: SCP Upload from Local Machine
```bash
# Run this from your local machine
scp -r "/Users/sebastianlarsen/Developer/Streams for Lovers/"* root@161.97.116.47:/opt/ai-music-stream/
```

### Option C: Manual File Creation (Immediate Start)
```bash
# Create the configuration file directly on server
cat > config/.env << 'EOF'
# Suno AI Music Generation API
SUNO_API_KEY=b4ec4a1698ed35aeaa76280d62fb8c77
SUNO_API_URL=https://api.sunoapi.org/api/v1
SUNO_API_TIMEOUT=60

# YouTube API Configuration (you need to add these)
YOUTUBE_API_KEY=your_youtube_data_api_key_here
YOUTUBE_CHANNEL_ID=your_youtube_channel_id_here
YOUTUBE_STREAM_KEY=your_youtube_live_stream_key_here

# Stream Configuration
STREAM_TITLE="City Pop Anime - Interactive AI Music 🎵✨"
STREAM_GENRE=city_pop_anime
TARGET_GENERATION_RATE=12
DAILY_BUDGET_USD=0.60

# Debug settings for initial testing
DEBUG_MODE=true
LOG_LEVEL=INFO
EOF
```

## Step 5: Set Up Virtual Display
```bash
# Create virtual display service
cat > /etc/systemd/system/virtual-display.service << 'EOF'
[Unit]
Description=Virtual Display for Headless Streaming
After=graphical-session.target

[Service]
Type=simple
User=root
Environment=DISPLAY=:1
ExecStart=/usr/bin/Xvfb :1 -screen 0 1920x1080x24
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start virtual display
systemctl enable virtual-display.service
systemctl start virtual-display.service
systemctl status virtual-display.service
```

## Step 6: Test Basic Setup
```bash
# Test Python environment
cd /opt/ai-music-stream
source venv/bin/activate
python3 -c "import requests; print('✅ Python setup working')"

# Test Suno API connection
python3 -c "
import os
import requests
os.environ['SUNO_API_KEY'] = 'b4ec4a1698ed35aeaa76280d62fb8c77'
try:
    response = requests.get('https://api.sunoapi.org/api/v1/health', 
                           headers={'Authorization': f'Bearer {os.environ[\"SUNO_API_KEY\"]}'}, 
                           timeout=10)
    print('✅ Suno API reachable')
except Exception as e:
    print(f'⚠️ Suno API test: {e}')
"

# Test virtual display
export DISPLAY=:1
xdpyinfo | head -5
echo "✅ Virtual display test complete"
```

## Step 7: Security Hardening
```bash
# Create non-root user for running services
useradd -m -s /bin/bash aistream
usermod -aG sudo aistream

# Set up SSH key authentication (optional but recommended)
mkdir -p /home/aistream/.ssh
# Copy your public key to /home/aistream/.ssh/authorized_keys

# Configure firewall
ufw allow 22      # SSH
ufw allow 80      # HTTP
ufw allow 443     # HTTPS
ufw allow 1935    # RTMP
ufw --force enable
```

## Step 8: Create Basic Service File
```bash
cat > /etc/systemd/system/ai-music-stream.service << 'EOF'
[Unit]
Description=Interactive AI Music Streaming Service
After=network.target virtual-display.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ai-music-stream
Environment=PATH=/opt/ai-music-stream/venv/bin
Environment=DISPLAY=:1
ExecStart=/opt/ai-music-stream/venv/bin/python src/main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Don't start service yet - we need to upload the code first
systemctl daemon-reload
```

## Next Steps Checklist
- [ ] Connect to server via SSH
- [ ] Run initial server setup commands
- [ ] Upload project files (choose method above)
- [ ] Get YouTube API keys and update config/.env
- [ ] Test basic functionality
- [ ] Start building the actual streaming application

## Quick Test Commands
```bash
# Check all services
systemctl status virtual-display
systemctl status ai-music-stream

# View logs
journalctl -u virtual-display -f
journalctl -u ai-music-stream -f

# Check disk space
df -h

# Check memory usage
free -h

# Check network
ping google.com
```

## If You Encounter Issues
```bash
# Check virtual display
ps aux | grep Xvfb
export DISPLAY=:1 && xdpyinfo

# Check Python environment
which python3
python3 --version
pip list

# Check permissions
ls -la /opt/ai-music-stream/
chown -R root:root /opt/ai-music-stream/
```

---

**You're ready to deploy! Start with Step 1 and work through each section.** 🚀