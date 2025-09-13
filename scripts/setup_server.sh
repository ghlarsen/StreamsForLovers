#!/bin/bash

# AI Music Stream Server Setup Script
# This script sets up the initial server environment and SSH keys

set -e

SERVER_IP="161.97.116.47"
REPO_URL="https://github.com/ghlarsen/StreamsForLovers.git"

echo "🚀 AI Music Stream - Server Setup"
echo "=================================="
echo "Server: $SERVER_IP"
echo "Repository: $REPO_URL"
echo ""

# Check if we can connect via SSH key (already set up)
if ssh -o ConnectTimeout=5 -o BatchMode=yes ai-stream-server "echo 'SSH key authentication working'" 2>/dev/null; then
    echo "✅ SSH key authentication already working"
    USE_SSH_KEY=true
else
    echo "⚠️  SSH key authentication not working - will need password"
    echo "Make sure you have the root password: TommyLiveRobinson12"
    USE_SSH_KEY=false
fi

echo ""
echo "📋 Server setup tasks:"
echo "1. Install system dependencies (Python, Git, etc.)"
echo "2. Clone repository to /opt/ai-music-stream"
echo "3. Set up Python virtual environment"
echo "4. Install Python dependencies"
echo "5. Create systemd services for dev and production"
echo "6. Set up SSH key for future deployments (if needed)"
echo ""

read -p "Continue with server setup? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo "Setup cancelled"
    exit 1
fi

# Function to run commands on server
run_on_server() {
    if [ "$USE_SSH_KEY" = true ]; then
        ssh ai-stream-server "$1"
    else
        echo "Run this command on the server manually:"
        echo "ssh root@$SERVER_IP"
        echo "Then run: $1"
        echo ""
        read -p "Press Enter when command is completed..."
    fi
}

echo ""
echo "🔧 Setting up server environment..."

# Install system dependencies
echo "Installing system dependencies..."
run_on_server "apt update && apt install -y python3 python3-pip python3-venv git curl htop"

# Create project directory and clone repository
echo "Setting up project directory..."
run_on_server "cd /opt && rm -rf ai-music-stream && git clone $REPO_URL ai-music-stream"

# Set up Python virtual environment
echo "Setting up Python virtual environment..."
run_on_server "cd /opt/ai-music-stream && python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip"

# Install Python dependencies (create requirements.txt first)
echo "Installing Python dependencies..."
run_on_server "cd /opt/ai-music-stream && source venv/bin/activate && pip install requests python-dotenv pyyaml"

# Set up SSH key for future deployments (if needed)
if [ "$USE_SSH_KEY" = false ]; then
    echo "Setting up SSH key for future deployments..."
    echo "Adding public key to server authorized_keys..."
    
    PUBLIC_KEY=$(cat ~/.ssh/deploy_ai_stream.pub)
    run_on_server "mkdir -p ~/.ssh && echo '$PUBLIC_KEY' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh"
    
    echo "Testing SSH key authentication..."
    if ssh -o ConnectTimeout=5 -o BatchMode=yes ai-stream-server "echo 'SSH key now working'" 2>/dev/null; then
        echo "✅ SSH key authentication now working"
        USE_SSH_KEY=true
    else
        echo "⚠️  SSH key authentication still not working - check server configuration"
    fi
fi

# Create systemd service files
echo "Creating systemd service files..."

# Production service
run_on_server "cat > /etc/systemd/system/ai-music-stream-prod.service << 'EOF'
[Unit]
Description=AI Music Stream Production
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ai-music-stream
Environment=PATH=/opt/ai-music-stream/venv/bin
ExecStart=/opt/ai-music-stream/venv/bin/python src/main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF"

# Development service
run_on_server "cat > /etc/systemd/system/ai-music-stream-dev.service << 'EOF'
[Unit]
Description=AI Music Stream Development
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ai-music-stream
Environment=PATH=/opt/ai-music-stream/venv/bin
ExecStart=/opt/ai-music-stream/venv/bin/python src/main.py
Restart=no
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF"

# Reload systemd and enable services
run_on_server "systemctl daemon-reload"

echo ""
echo "✅ Server setup complete!"
echo ""
echo "📊 Next steps:"
echo "1. Configure YouTube API keys in config/.env.prod and config/.env.dev"
echo "2. Test deployment with: ./deploy.sh dev"
echo "3. Test production deployment with: ./deploy.sh"
echo ""
echo "📋 Useful commands:"
echo "  SSH to server: ssh ai-stream-server"
echo "  Check production service: systemctl status ai-music-stream-prod"
echo "  Check development service: systemctl status ai-music-stream-dev"
echo "  View production logs: journalctl -u ai-music-stream-prod -f"
echo "  View development logs: journalctl -u ai-music-stream-dev -f"