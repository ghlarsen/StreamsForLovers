#!/bin/bash

# Enhanced deployment script for AI Music Stream
# Supports both development and production environments

set -e

# Parse environment argument
ENVIRONMENT=${1:-production}
SERVER_IP="161.97.116.47"

# Environment-specific configuration
if [ "$ENVIRONMENT" = "dev" ] || [ "$ENVIRONMENT" = "development" ]; then
    echo "🧪 AI Music Stream - DEVELOPMENT Deployment"
    BRANCH="dev"
    SERVICE="ai-music-stream-dev"
    CONFIG=".env.dev"
    PORT="8081"
else
    echo "🚀 AI Music Stream - PRODUCTION Deployment"
    BRANCH="main"
    SERVICE="ai-music-stream-prod"  
    CONFIG=".env.prod"
    PORT="8080"
fi

echo "=============================="
echo "Environment: $ENVIRONMENT"
echo "Branch: $BRANCH"
echo "Service: $SERVICE"
echo "Config: $CONFIG"
echo "=============================="

# Check for uncommitted changes
if ! git diff --quiet HEAD 2>/dev/null || [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "📝 Uncommitted changes detected"
    git status --short
    read -p "Commit changes? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        read -p "Commit message: " COMMIT_MSG
        if [ -z "$COMMIT_MSG" ]; then
            COMMIT_MSG="🔄 Update $ENVIRONMENT deployment $(date '+%Y-%m-%d %H:%M')"
        fi
        git add .
        git commit -m "$COMMIT_MSG"
    fi
fi

# Ensure we're on the correct branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    echo "⚠️  Currently on branch '$CURRENT_BRANCH', switching to '$BRANCH'..."
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
fi

# Push to GitHub
echo "📤 Pushing to GitHub ($BRANCH)..."
git push origin "$BRANCH"

# Deploy to server
echo "🚀 Deploying to server..."
ssh root@$SERVER_IP "
    echo '=== Server Deployment Started ===' &&
    cd /opt/ai-music-stream &&
    
    # Switch to correct branch
    git fetch origin &&
    git checkout $BRANCH &&
    git pull origin $BRANCH &&
    
    # Use correct environment config
    cp config/$CONFIG config/.env &&
    
    # Activate Python environment
    source venv/bin/activate &&
    
    # Update dependencies if requirements changed
    pip install -r requirements.txt &&
    
    # Restart the appropriate service
    if systemctl is-active --quiet $SERVICE; then
        echo 'Restarting existing service...' &&
        systemctl restart $SERVICE
    else
        echo 'Starting service...' &&
        systemctl start $SERVICE
    fi &&
    
    # Wait for service to start
    sleep 5 &&
    
    # Check service status
    if systemctl is-active --quiet $SERVICE; then
        echo '✅ $SERVICE is running successfully'
    else
        echo '❌ $SERVICE failed to start'
        systemctl status $SERVICE
        exit 1
    fi &&
    
    echo '=== Deployment Complete ==='
"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment successful!"
    echo ""
    echo "📊 Post-deployment checks:"
    echo "  Service status: ssh root@$SERVER_IP 'systemctl status $SERVICE'"
    echo "  Live logs: ssh root@$SERVER_IP 'journalctl -u $SERVICE -f'"
    echo "  Health check: curl http://$SERVER_IP:$PORT/health"
    echo ""
    if [ "$ENVIRONMENT" = "dev" ]; then
        echo "🧪 Development stream: http://$SERVER_IP:$PORT"
        echo "⚠️  Remember: This is a PRIVATE test stream"
    else
        echo "🎵 Production stream: Live on YouTube"
        echo "📈 Monitor metrics and viewer engagement"
    fi
else
    echo ""
    echo "❌ Deployment failed!"
    echo "Check server logs: ssh root@$SERVER_IP 'journalctl -u $SERVICE -f'"
    exit 1
fi