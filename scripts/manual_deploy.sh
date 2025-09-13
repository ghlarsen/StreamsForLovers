#!/bin/bash

# Manual Deployment Script for AI Music Stream
# Use this when SSH keys aren't set up yet

set -e

SERVER_IP="161.97.116.47"
REPO_URL="https://github.com/ghlarsen/StreamsForLovers.git"

echo "🚀 AI Music Stream - Manual Deployment"
echo "======================================"
echo "Server: $SERVER_IP"
echo "Password: TommyLiveRobinson12"
echo "Repository: $REPO_URL"
echo ""

# Check environment
ENVIRONMENT=${1:-production}
if [ "$ENVIRONMENT" = "dev" ] || [ "$ENVIRONMENT" = "development" ]; then
    SERVICE="ai-music-stream-dev"
    CONFIG=".env.dev"
    echo "🧪 Deploying DEVELOPMENT environment"
else
    SERVICE="ai-music-stream-prod"  
    CONFIG=".env.prod"
    echo "🚀 Deploying PRODUCTION environment"
fi

echo "Service: $SERVICE"
echo "Config: $CONFIG"
echo ""

# Push latest changes to GitHub first
echo "📤 Pushing latest changes to GitHub..."
git push origin main

echo ""
echo "🔧 Server Commands to Run:"
echo "=========================="
echo "1. Connect to server:"
echo "   ssh root@$SERVER_IP"
echo ""
echo "2. Update repository:"
echo "   cd /opt/ai-music-stream"
echo "   git pull origin main"
echo ""
echo "3. Activate Python environment:"
echo "   source venv/bin/activate"
echo ""
echo "4. Update dependencies (if needed):"
echo "   pip install -r requirements.txt"
echo ""
echo "5. Configure environment:"
echo "   cp config/$CONFIG config/.env"
echo ""
echo "6. Restart service:"
echo "   systemctl restart $SERVICE"
echo ""
echo "7. Check service status:"
echo "   systemctl status $SERVICE"
echo ""
echo "8. View logs:"
echo "   journalctl -u $SERVICE -f"
echo ""

echo "📋 Run these commands on the server, then press Enter to continue..."
read -p ""

echo ""
echo "🧪 Testing deployment..."
echo "Commands to test on the server:"
echo ""
echo "# Check if service is running:"
echo "systemctl is-active $SERVICE"
echo ""
echo "# View recent logs:"
echo "journalctl -u $SERVICE -n 20"
echo ""
echo "# Check application logs:"
echo "tail -f /opt/ai-music-stream/logs/app.log"
echo ""

if [ "$ENVIRONMENT" = "dev" ]; then
    echo "🧪 Development environment deployed"
    echo "Remember: This uses the private test stream configuration"
else
    echo "🚀 Production environment deployed"
    echo "Remember: This will use the live YouTube stream"
fi

echo ""
echo "✅ Manual deployment process complete!"
echo "The service should now be running on the server."