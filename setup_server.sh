#!/bin/bash

# Interactive AI Music Streaming Server Setup Script
# For Ubuntu Server on Contabo VPS

set -e

echo "🎵 Interactive AI Music Streaming Server Setup"
echo "============================================="

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo "🔧 Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    ffmpeg \
    xvfb \
    pulseaudio \
    alsa-utils \
    v4l2loopback-utils \
    software-properties-common

# Install OBS Studio
echo "🎬 Installing OBS Studio..."
sudo add-apt-repository ppa:obsproject/obs-studio -y
sudo apt update
sudo apt install -y obs-studio

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/ai-music-stream
sudo chown $USER:$USER /opt/ai-music-stream
cd /opt/ai-music-stream

# Create Python virtual environment
echo "🐍 Setting up Python environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "📚 Installing Python dependencies..."
pip install --upgrade pip
pip install \
    requests \
    websocket-client \
    python-dotenv \
    asyncio \
    aiohttp \
    youtube-dl \
    pytchat \
    obs-websocket-py

# Create directory structure
echo "📂 Creating directory structure..."
mkdir -p {src,config,logs,music,videos,scripts}

# Create systemd service file
echo "⚙️ Creating systemd service..."
sudo tee /etc/systemd/system/ai-music-stream.service > /dev/null <<EOF
[Unit]
Description=Interactive AI Music Streaming Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/ai-music-stream
Environment=PATH=/opt/ai-music-stream/venv/bin
ExecStart=/opt/ai-music-stream/venv/bin/python src/main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Setup virtual display
echo "🖥️ Configuring virtual display..."
sudo tee /etc/systemd/system/virtual-display.service > /dev/null <<EOF
[Unit]
Description=Virtual Display for Headless Streaming
After=graphical-session.target

[Service]
Type=simple
User=$USER
Environment=DISPLAY=:1
ExecStart=/usr/bin/Xvfb :1 -screen 0 1920x1080x24
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable services
sudo systemctl daemon-reload
sudo systemctl enable virtual-display.service

echo "✅ Server setup complete!"
echo "📋 Next steps:"
echo "   1. Configure your API keys in config/.env"
echo "   2. Set up YouTube Live stream key"
echo "   3. Run the application with: systemctl start ai-music-stream"
echo ""
echo "🔧 Useful commands:"
echo "   - Check logs: journalctl -u ai-music-stream -f"
echo "   - Restart service: systemctl restart ai-music-stream"
echo "   - Start virtual display: systemctl start virtual-display"