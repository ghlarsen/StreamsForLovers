# 🚀 AI Music Stream - Deployment Guide

This guide walks through deploying the AI Music Streaming Platform to the Contabo server.

## 📋 Server Information
- **Server IP**: 161.97.116.47
- **Username**: root
- **Password**: TommyLiveRobinson12
- **Repository**: https://github.com/ghlarsen/StreamsForLovers.git

## 🔧 One-Time Server Setup

### Step 1: Connect to Server
```bash
ssh root@161.97.116.47
# Password: TommyLiveRobinson12
```

### Step 2: Install System Dependencies
```bash
# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y python3 python3-pip python3-venv git curl htop nano ffmpeg

# Install Node.js (for potential future features)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Verify installations
python3 --version
git --version
node --version
```

### Step 3: Clone Repository
```bash
# Navigate to /opt directory
cd /opt

# Remove any existing installation
rm -rf ai-music-stream

# Clone the repository
git clone https://github.com/ghlarsen/StreamsForLovers.git ai-music-stream

# Navigate to project
cd ai-music-stream
```

### Step 4: Set Up Python Environment
```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install basic dependencies
pip install requests python-dotenv

# Install full requirements (may take a few minutes)
pip install -r requirements.txt
```

### Step 5: Create Log Directory
```bash
# Create logs directory
mkdir -p /opt/ai-music-stream/logs

# Set permissions
chmod 755 /opt/ai-music-stream/logs
```

### Step 6: Set Up SSH Key (Optional but Recommended)
```bash
# Create SSH directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add the deploy key (paste the public key content)
nano ~/.ssh/authorized_keys
# Paste this content:
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC5t... (your deploy key)

# Set proper permissions
chmod 600 ~/.ssh/authorized_keys
```

### Step 7: Create Systemd Services

#### Production Service
```bash
cat > /etc/systemd/system/ai-music-stream-prod.service << 'EOF'
[Unit]
Description=AI Music Stream Production
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ai-music-stream
Environment=PATH=/opt/ai-music-stream/venv/bin
ExecStart=/opt/ai-music-stream/venv/bin/python src/simple_main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
```

#### Development Service
```bash
cat > /etc/systemd/system/ai-music-stream-dev.service << 'EOF'
[Unit]
Description=AI Music Stream Development
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ai-music-stream
Environment=PATH=/opt/ai-music-stream/venv/bin
ExecStart=/opt/ai-music-stream/venv/bin/python src/simple_main.py
Restart=no
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

#### Reload Systemd
```bash
systemctl daemon-reload
```

### Step 8: Configure Environment
```bash
# Copy development configuration
cp config/.env.dev config/.env

# Edit configuration if needed
nano config/.env
```

## 🚀 Deployment Process

Once the server is set up, you can deploy using the deployment script:

### Deploy Development Version
```bash
# From your local machine
./deploy.sh dev
```

### Deploy Production Version
```bash
# From your local machine
./deploy.sh
```

## 📊 Managing Services

### Start Services
```bash
# Start development service
systemctl start ai-music-stream-dev

# Start production service
systemctl start ai-music-stream-prod
```

### Check Status
```bash
# Check development service
systemctl status ai-music-stream-dev

# Check production service
systemctl status ai-music-stream-prod
```

### View Logs
```bash
# Development logs
journalctl -u ai-music-stream-dev -f

# Production logs
journalctl -u ai-music-stream-prod -f

# Application logs
tail -f /opt/ai-music-stream/logs/app.log
```

### Stop Services
```bash
# Stop development service
systemctl stop ai-music-stream-dev

# Stop production service
systemctl stop ai-music-stream-prod
```

## 🧪 Testing Deployment

### Test Development Environment
```bash
# Deploy to development
./deploy.sh dev

# Check if service is running
ssh root@161.97.116.47 'systemctl status ai-music-stream-dev'

# View logs
ssh root@161.97.116.47 'journalctl -u ai-music-stream-dev -n 20'

# Test health (if HTTP endpoint is added)
curl http://161.97.116.47:8081/health
```

### Test Production Environment
```bash
# Deploy to production
./deploy.sh

# Check if service is running
ssh root@161.97.116.47 'systemctl status ai-music-stream-prod'

# View logs
ssh root@161.97.116.47 'journalctl -u ai-music-stream-prod -n 20'

# Test health (if HTTP endpoint is added)
curl http://161.97.116.47:8080/health
```

## 🛠️ Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check logs for errors
journalctl -u ai-music-stream-prod -n 50

# Check if config file exists
ls -la /opt/ai-music-stream/config/.env

# Test Python environment
cd /opt/ai-music-stream
source venv/bin/activate
python src/simple_main.py
```

#### Git Issues
```bash
# If git pull fails, reset to remote
cd /opt/ai-music-stream
git reset --hard origin/main
git pull origin main
```

#### Permission Issues
```bash
# Fix ownership
chown -R root:root /opt/ai-music-stream

# Fix permissions
chmod +x /opt/ai-music-stream/deploy.sh
chmod 755 /opt/ai-music-stream/src/simple_main.py
```

#### Python Dependencies
```bash
# Reinstall dependencies
cd /opt/ai-music-stream
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

## 🔄 Update Process

### Regular Updates
```bash
# Development
./deploy.sh dev

# Production (when ready)
./deploy.sh
```

### Emergency Updates
```bash
# Hotfix branch
git checkout -b hotfix/critical-fix
# Make fixes...
git commit -m "Critical fix"
git checkout main
git merge hotfix/critical-fix
./deploy.sh
```

## 📈 Monitoring

### Service Health
```bash
# Check if services are active
systemctl is-active ai-music-stream-prod
systemctl is-active ai-music-stream-dev

# Check uptime
systemctl show ai-music-stream-prod --property=ActiveEnterTimestamp
```

### Resource Usage
```bash
# Check system resources
htop

# Check disk space
df -h

# Check memory usage
free -h

# Check process status
ps aux | grep python
```

### Logs Monitoring
```bash
# Real-time logs
journalctl -u ai-music-stream-prod -f

# Recent errors only
journalctl -u ai-music-stream-prod -p err -n 20

# Application logs
tail -f /opt/ai-music-stream/logs/app.log
```

---

## ✅ Deployment Checklist

- [ ] Server connected and dependencies installed
- [ ] Repository cloned to /opt/ai-music-stream
- [ ] Python virtual environment created and activated
- [ ] Dependencies installed from requirements.txt
- [ ] Systemd services created and loaded
- [ ] SSH key configured (optional)
- [ ] Development deployment tested
- [ ] Production deployment tested
- [ ] Services running and logs healthy
- [ ] Monitoring set up

**Ready for YouTube API integration and Stage 1 MVP launch!** 🎵✨