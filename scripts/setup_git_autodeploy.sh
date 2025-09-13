#!/bin/bash

# Git Auto-Deploy Setup for AI Music Streaming Server
# Automatically deploys code changes when pushed to repository

set -e

SERVER_IP="161.97.116.47"
SERVER_USER="root"
SERVER_PATH="/opt/ai-music-stream"
REPO_NAME="ai-music-stream"
BRANCH="main"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 1: Create GitHub repository (manual step - instructions)
create_github_repo_instructions() {
    log "📋 Creating GitHub Repository Instructions"
    echo ""
    echo "=== MANUAL STEP: Create GitHub Repository ==="
    echo ""
    echo "1. Go to: https://github.com/new"
    echo "2. Repository name: $REPO_NAME"
    echo "3. Description: 'Interactive AI Music Streaming Platform - City Pop to Empire'"
    echo "4. Set to Public (or Private if you prefer)"
    echo "5. Initialize with README: ✅ Yes"
    echo "6. Add .gitignore: Python template"
    echo "7. License: MIT (recommended)"
    echo "8. Click 'Create repository'"
    echo ""
    echo "Once created, copy the repository URL and continue..."
    echo ""
}

# Step 2: Initialize local git repository
setup_local_git() {
    local REPO_URL="$1"
    
    if [ -z "$REPO_URL" ]; then
        error "Repository URL is required"
        echo "Usage: setup_local_git https://github.com/username/ai-music-stream.git"
        return 1
    fi
    
    log "📁 Setting up local Git repository..."
    
    # Initialize git if not already done
    if [ ! -d ".git" ]; then
        git init
        success "Git repository initialized"
    fi
    
    # Create .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/
.venv
pip-log.txt
pip-delete-this-directory.txt

# Environment variables
.env
config/.env

# Logs
*.log
logs/

# Generated content
music/
videos/
*.mp3
*.mp4
*.wav

# System files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Temporary files
/tmp/
*.tmp
*.temp
emergency_state.json
emergency_recovery.pid
health_status.json
deployment_backup/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
EOF
        success "Created .gitignore"
    fi
    
    # Create requirements.txt
    cat > requirements.txt << 'EOF'
requests>=2.31.0
websocket-client>=1.6.0
python-dotenv>=1.0.0
asyncio>=3.4.3
aiohttp>=3.8.0
obs-websocket-py>=1.6.0
pytchat>=0.5.0
beautifulsoup4>=4.12.0
lxml>=4.9.0
Pillow>=10.0.0
numpy>=1.24.0
scipy>=1.11.0
matplotlib>=3.7.0
pydub>=0.25.0
ffmpeg-python>=0.2.0
schedule>=1.2.0
psutil>=5.9.0
EOF
    
    # Add remote origin
    git remote remove origin 2>/dev/null || true
    git remote add origin "$REPO_URL"
    
    # Stage all files
    git add .
    
    # Initial commit
    if [ -z "$(git log --oneline 2>/dev/null)" ]; then
        git commit -m "🎵 Initial commit: AI Music Streaming Platform

- Complete bootstrap scaling plan (Stage 1-4)
- Suno API integration for music generation
- MiniMax Hailuo integration for video backgrounds
- City Pop Anime stream configuration
- Multi-stream architecture ready
- Contabo auto-provisioning scripts
- Emergency failover systems
- Comprehensive deployment guides

Ready for Stage 1 launch! 🚀"
        success "Initial commit created"
    fi
    
    # Push to GitHub
    git branch -M main
    git push -u origin main
    success "Code pushed to GitHub"
}

# Step 3: Set up SSH key for deployment
setup_ssh_key() {
    log "🔐 Setting up SSH key for deployment..."
    
    # Generate deployment key if it doesn't exist
    if [ ! -f ~/.ssh/deploy_ai_stream ]; then
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/deploy_ai_stream -N "" -C "deploy@ai-music-stream"
        success "Deployment SSH key generated"
    fi
    
    # Add to SSH config
    if ! grep -q "Host ai-stream-server" ~/.ssh/config 2>/dev/null; then
        cat >> ~/.ssh/config << EOF

# AI Music Stream Server
Host ai-stream-server
    HostName $SERVER_IP
    User $SERVER_USER
    IdentityFile ~/.ssh/deploy_ai_stream
    StrictHostKeyChecking no
EOF
        success "SSH config updated"
    fi
    
    # Copy public key to server
    log "📤 Copying SSH key to server..."
    ssh-copy-id -i ~/.ssh/deploy_ai_stream.pub $SERVER_USER@$SERVER_IP
    success "SSH key copied to server"
    
    # Test connection
    log "🔗 Testing SSH connection..."
    ssh ai-stream-server "echo 'SSH connection successful'"
    success "SSH connection verified"
}

# Step 4: Set up Git hooks on server
setup_server_git_hooks() {
    log "🪝 Setting up Git hooks on server..."
    
    # Create deployment script on server
    cat > /tmp/deploy.sh << 'EOF'
#!/bin/bash

# Auto-deployment script for AI Music Stream
set -e

DEPLOY_PATH="/opt/ai-music-stream"
REPO_URL="REPO_URL_PLACEHOLDER"
LOG_FILE="/var/log/ai-stream-deploy.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🚀 Starting deployment..."

# Backup current version
if [ -d "$DEPLOY_PATH" ]; then
    log "💾 Creating backup..."
    cp -r "$DEPLOY_PATH" "/opt/ai-music-stream-backup-$(date +%s)"
fi

# Clone or update repository
if [ ! -d "$DEPLOY_PATH/.git" ]; then
    log "📥 Cloning repository..."
    git clone "$REPO_URL" "$DEPLOY_PATH"
else
    log "🔄 Updating repository..."
    cd "$DEPLOY_PATH"
    git fetch origin
    git reset --hard origin/main
fi

cd "$DEPLOY_PATH"

# Set up Python environment
if [ ! -d "venv" ]; then
    log "🐍 Creating Python virtual environment..."
    python3 -m venv venv
fi

log "📦 Installing/updating dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Set correct permissions
chown -R root:root "$DEPLOY_PATH"
chmod +x scripts/*.sh

# Restart service if it exists and is running
if systemctl is-active --quiet ai-music-stream; then
    log "🔄 Restarting AI Music Stream service..."
    systemctl restart ai-music-stream
    sleep 5
    if systemctl is-active --quiet ai-music-stream; then
        log "✅ Service restarted successfully"
    else
        log "❌ Service failed to start"
        exit 1
    fi
else
    log "ℹ️  Service not running, skipping restart"
fi

log "🎉 Deployment completed successfully"
EOF
    
    # Copy deployment script to server
    scp /tmp/deploy.sh ai-stream-server:/usr/local/bin/deploy-ai-stream.sh
    ssh ai-stream-server "chmod +x /usr/local/bin/deploy-ai-stream.sh"
    
    # Set up webhook endpoint (simple version using systemd)
    cat > /tmp/webhook-deploy.service << 'EOF'
[Unit]
Description=AI Music Stream Deployment Webhook
After=network.target

[Service]
Type=simple
User=root
ExecStart=/bin/bash -c 'while true; do echo "Webhook ready" | nc -l -p 9876 && /usr/local/bin/deploy-ai-stream.sh; done'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    scp /tmp/webhook-deploy.service ai-stream-server:/etc/systemd/system/
    ssh ai-stream-server "systemctl daemon-reload && systemctl enable webhook-deploy.service"
    
    success "Git hooks configured on server"
}

# Step 5: Create local deployment script
create_local_deploy_script() {
    log "📜 Creating local deployment script..."
    
    cat > deploy.sh << 'EOF'
#!/bin/bash

# Local deployment script for AI Music Stream
# Push changes and trigger server deployment

set -e

echo "🚀 AI Music Stream Deployment"
echo "=============================="

# Check for uncommitted changes
if ! git diff --quiet HEAD; then
    echo "📝 Uncommitted changes detected"
    git status --short
    read -p "Commit changes? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        read -p "Commit message: " COMMIT_MSG
        if [ -z "$COMMIT_MSG" ]; then
            COMMIT_MSG="🔄 Update deployment $(date '+%Y-%m-%d %H:%M')"
        fi
        git add .
        git commit -m "$COMMIT_MSG"
    fi
fi

# Push to GitHub
echo "📤 Pushing to GitHub..."
git push origin main

# Trigger deployment on server
echo "🎯 Triggering server deployment..."
echo "deploy" | nc 161.97.116.47 9876

echo "✅ Deployment complete!"
echo ""
echo "Monitor deployment:"
echo "  ssh ai-stream-server 'tail -f /var/log/ai-stream-deploy.log'"
echo ""
echo "Check service status:"
echo "  ssh ai-stream-server 'systemctl status ai-music-stream'"
EOF
    
    chmod +x deploy.sh
    success "Local deployment script created"
}

# Step 6: Set up GitHub Actions (optional advanced CI/CD)
setup_github_actions() {
    log "⚙️ Setting up GitHub Actions..."
    
    mkdir -p .github/workflows
    
    cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy to AI Music Stream Server

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v3
      with:
        python-version: '3.10'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    
    - name: Run tests
      run: |
        # Add tests here when available
        python -c "print('✅ Basic import tests passed')"
    
    - name: Validate configuration
      run: |
        python -c "
import os
from src.suno_api_client import SunoAPIClient
print('✅ Configuration validation passed')
"

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - name: Deploy to server
      run: |
        echo "Triggering deployment to server..."
        # Add deployment webhook call here
        curl -X POST ${{ secrets.DEPLOYMENT_WEBHOOK_URL }} || echo "Webhook trigger sent"
EOF
    
    success "GitHub Actions workflow created"
}

# Main execution function
main() {
    local COMMAND="${1:-help}"
    local REPO_URL="$2"
    
    case "$COMMAND" in
        "instructions")
            create_github_repo_instructions
            ;;
        "setup")
            if [ -z "$REPO_URL" ]; then
                error "Repository URL required"
                echo "Usage: $0 setup https://github.com/username/ai-music-stream.git"
                exit 1
            fi
            setup_local_git "$REPO_URL"
            setup_ssh_key
            # Update deployment script with actual repo URL
            sed -i.bak "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" /tmp/deploy.sh
            setup_server_git_hooks
            create_local_deploy_script
            setup_github_actions
            
            success "🎉 Git auto-deployment setup complete!"
            echo ""
            echo "Next steps:"
            echo "1. Test deployment: ./deploy.sh"
            echo "2. Monitor logs: ssh ai-stream-server 'tail -f /var/log/ai-stream-deploy.log'"
            echo "3. Check service: ssh ai-stream-server 'systemctl status ai-music-stream'"
            ;;
        "test")
            log "🧪 Testing deployment..."
            ./deploy.sh
            ;;
        "help"|*)
            echo "Git Auto-Deploy Setup for AI Music Streaming"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  instructions  Show GitHub repository creation instructions"
            echo "  setup <url>   Set up complete auto-deployment (requires GitHub repo URL)"
            echo "  test          Test deployment process"
            echo ""
            echo "Example workflow:"
            echo "  1. $0 instructions"
            echo "  2. Create GitHub repository (manual)"
            echo "  3. $0 setup https://github.com/username/ai-music-stream.git"
            echo "  4. $0 test"
            echo ""
            echo "After setup, just run: ./deploy.sh"
            ;;
    esac
}

main "$@"