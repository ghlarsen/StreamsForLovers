#!/bin/bash

# Simple deployment script for AI Music Stream
# Push changes and manually deploy to server

set -e

echo "🚀 AI Music Stream Deployment"
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
            COMMIT_MSG="🔄 Update deployment $(date '+%Y-%m-%d %H:%M')"
        fi
        git add .
        git commit -m "$COMMIT_MSG"
    fi
fi

# Push to GitHub
echo "📤 Pushing to GitHub..."
git push origin main

echo "✅ Code pushed to GitHub!"
echo ""
echo "Next steps:"
echo "1. SSH to server: ssh root@161.97.116.47"
echo "2. Run deployment: cd /opt/ai-music-stream && git pull origin main"
echo "3. Restart service: systemctl restart ai-music-stream"
echo ""
echo "Or use the manual deployment command:"
echo "ssh root@161.97.116.47 'cd /opt/ai-music-stream && git pull origin main && systemctl restart ai-music-stream'"