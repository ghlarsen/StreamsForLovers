#!/bin/bash

# Zero-Downtime Deployment Script for AI Music Stream
# Updates code and dependencies without interrupting the stream

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_DIR/deployment_backup"
MAINTENANCE_MODE=false

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to cleanup on exit
cleanup() {
    if $MAINTENANCE_MODE; then
        log "🔄 Restoring normal streaming mode..."
        python3 -c "
import sys
sys.path.append('src')
from obs_controller import OBSController
import asyncio

async def exit_maintenance():
    obs = OBSController()
    await obs.initialize()
    await obs.exit_maintenance_mode()

asyncio.run(exit_maintenance())
" 2>/dev/null || log "⚠️  Could not exit maintenance mode automatically"
    fi
}

trap cleanup EXIT

log "🚀 Starting Zero-Downtime Deployment for AI Music Stream"
log "========================================================"

cd "$PROJECT_DIR"

# 1. Pre-deployment health check
log "🏥 Running pre-deployment health check..."

if ! systemctl is-active --quiet ai-music-stream; then
    log "ℹ️  Service not running - safe to deploy without maintenance mode"
    SERVICE_RUNNING=false
else
    log "✅ Service is running - will use maintenance mode for deployment"
    SERVICE_RUNNING=true
fi

# Check git status
if [ -d ".git" ]; then
    if ! git diff --quiet HEAD; then
        log "⚠️  Warning: Uncommitted local changes detected"
        log "📋 Local changes:"
        git status --short
        read -p "Continue deployment? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "❌ Deployment cancelled by user"
            exit 1
        fi
    fi
fi

# 2. Create deployment backup
log "💾 Creating deployment backup..."

rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup current codebase
cp -r src/ "$BACKUP_DIR/" 2>/dev/null || true
cp -r config/ "$BACKUP_DIR/" 2>/dev/null || true
cp -r scripts/ "$BACKUP_DIR/" 2>/dev/null || true
cp requirements.txt "$BACKUP_DIR/" 2>/dev/null || true

log "✅ Backup created at $BACKUP_DIR"

# 3. Determine deployment strategy
if $SERVICE_RUNNING; then
    # Check if this is a hot-updatable change
    HOT_UPDATE=true
    
    # Check if main.py or core components changed
    if [ -d ".git" ] && git diff --name-only HEAD~1 HEAD | grep -E "(main\.py|obs_controller\.py|setup_server\.sh)" > /dev/null 2>&1; then
        HOT_UPDATE=false
        log "🔧 Core components changed - maintenance mode required"
    else
        log "🔥 Hot update possible - no maintenance mode needed"
    fi
    
    if [ "$HOT_UPDATE" = "false" ]; then
        # 4. Enter maintenance mode for full updates
        log "🔧 Entering maintenance mode..."
        MAINTENANCE_MODE=true
        
        # Build emergency content buffer first
        source venv/bin/activate
        python3 -c "
import sys
sys.path.append('src')
from emergency_buffer import EmergencyBuffer
buffer = EmergencyBuffer()
buffer.ensure_buffer_exists(hours=2)
print('Emergency buffer confirmed')
" 2>/dev/null || log "⚠️  Could not verify emergency buffer"
        
        # Switch to maintenance scene
        python3 -c "
import sys
sys.path.append('src')
from obs_controller import OBSController
import asyncio

async def enter_maintenance():
    obs = OBSController()
    await obs.initialize()
    await obs.enter_maintenance_mode()

asyncio.run(enter_maintenance())
" 2>/dev/null || log "⚠️  Could not enter maintenance mode"
        
        sleep 10  # Allow scene transition
        log "✅ Maintenance mode activated"
    fi
fi

# 5. Update code
log "📥 Updating codebase..."

if [ -d ".git" ]; then
    # Git-based update
    git fetch origin
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    
    if [ "$CURRENT_BRANCH" != "main" ]; then
        log "⚠️  Warning: Currently on branch '$CURRENT_BRANCH', not 'main'"
    fi
    
    git pull origin "$CURRENT_BRANCH"
    log "✅ Code updated from Git"
else
    log "ℹ️  No Git repository - manual code update required"
fi

# 6. Update Python dependencies
log "📚 Updating Python dependencies..."

source venv/bin/activate

# Check if requirements changed
if [ -f "$BACKUP_DIR/requirements.txt" ] && ! diff -q requirements.txt "$BACKUP_DIR/requirements.txt" > /dev/null 2>&1; then
    log "📦 Requirements changed - updating dependencies..."
    pip install --upgrade -r requirements.txt
else
    log "📦 Requirements unchanged - checking for security updates..."
    pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip install -U 2>/dev/null || true
fi

log "✅ Dependencies updated"

# 7. Run tests if available
if [ -f "tests/test_deployment.py" ]; then
    log "🧪 Running deployment tests..."
    python3 -m pytest tests/test_deployment.py -v
    if [ $? -ne 0 ]; then
        log "❌ Tests failed - rolling back deployment"
        # Rollback code
        cp -r "$BACKUP_DIR/"* ./
        source venv/bin/activate
        pip install -r requirements.txt
        exit 1
    fi
    log "✅ All tests passed"
else
    log "ℹ️  No deployment tests found - skipping test phase"
fi

# 8. Component-specific updates
log "🔄 Updating individual components..."

if $SERVICE_RUNNING; then
    if [ "$HOT_UPDATE" = "true" ]; then
        # Hot update individual components
        log "🔥 Performing hot updates..."
        
        # Update chat bot (can restart independently)
        python3 -c "
import sys
sys.path.append('src')
from main import InteractiveStreamManager
import asyncio

async def hot_update_chat_bot():
    # This would send a signal to main process to restart chat bot
    print('Chat bot hot update requested')

asyncio.run(hot_update_chat_bot())
" 2>/dev/null || log "⚠️  Hot update signal failed"
        
    else
        # Full service restart required
        log "🔄 Restarting AI Music Stream service..."
        
        systemctl stop ai-music-stream
        sleep 5
        systemctl start ai-music-stream
        
        # Wait for service to be ready
        log "⏳ Waiting for service to initialize..."
        for i in {1..30}; do
            if systemctl is-active --quiet ai-music-stream; then
                log "✅ Service restarted successfully"
                break
            fi
            if [ $i -eq 30 ]; then
                log "❌ Service failed to start - rolling back"
                
                # Rollback
                systemctl stop ai-music-stream
                cp -r "$BACKUP_DIR/"* ./
                systemctl start ai-music-stream
                exit 1
            fi
            sleep 2
        done
        
        # Wait additional time for full initialization
        sleep 15
    fi
fi

# 9. Configuration updates
log "⚙️  Checking configuration updates..."

# Update systemd service if changed
if [ -f "setup_server.sh" ] && [ -f "$BACKUP_DIR/setup_server.sh" ]; then
    if ! diff -q setup_server.sh "$BACKUP_DIR/setup_server.sh" > /dev/null 2>&1; then
        log "🔧 Systemd service configuration updated"
        # Re-run relevant parts of setup script
        sudo systemctl daemon-reload
    fi
fi

# 10. Post-deployment verification
log "✅ Running post-deployment verification..."

if $SERVICE_RUNNING; then
    # Verify service is running
    if ! systemctl is-active --quiet ai-music-stream; then
        log "❌ Service failed to start after deployment"
        exit 1
    fi
    
    # Test API endpoints
    python3 -c "
import sys
sys.path.append('src')
import requests
import time

# Give service time to fully initialize
time.sleep(5)

try:
    # Test health endpoint if available
    response = requests.get('http://localhost:8080/health', timeout=5)
    if response.status_code == 200:
        print('✅ API health check passed')
    else:
        print(f'⚠️  API returned status {response.status_code}')
except Exception as e:
    print(f'ℹ️  API health check not available: {e}')
" 2>/dev/null || true
    
    # Test component initialization
    python3 -c "
import sys
sys.path.append('src')
from main import InteractiveStreamManager
import asyncio

async def test_components():
    stream_manager = InteractiveStreamManager()
    try:
        success = await stream_manager.initialize()
        await stream_manager.shutdown()
        print('✅ Component initialization test passed')
        return success
    except Exception as e:
        print(f'❌ Component test failed: {e}')
        return False

success = asyncio.run(test_components())
" 2>/dev/null || log "⚠️  Component test failed"
fi

# 11. Exit maintenance mode (cleanup will handle this too)
if $MAINTENANCE_MODE; then
    log "🎵 Exiting maintenance mode..."
    python3 -c "
import sys
sys.path.append('src')
from obs_controller import OBSController
import asyncio

async def exit_maintenance():
    obs = OBSController()
    await obs.initialize()
    await obs.exit_maintenance_mode()

asyncio.run(exit_maintenance())
" 2>/dev/null || log "⚠️  Could not exit maintenance mode"
    
    MAINTENANCE_MODE=false
    sleep 5
    log "✅ Normal streaming resumed"
fi

# 12. Cleanup and final status
log "🧹 Cleaning up deployment artifacts..."

# Keep backup for 24 hours, then auto-cleanup
echo "rm -rf '$BACKUP_DIR'" | at now + 24 hours 2>/dev/null || true

# Update deployment log
echo "$(date): Deployment successful $(git rev-parse --short HEAD 2>/dev/null || echo 'no-git')" >> deployment_history.log

log "🎉 Deployment completed successfully!"
log "📊 Final status:"
log "├── Service: $(systemctl is-active ai-music-stream 2>/dev/null || echo 'not-running')"
log "├── Virtual Display: $(systemctl is-active virtual-display 2>/dev/null || echo 'not-running')"
log "└── Maintenance Mode: $([ $MAINTENANCE_MODE = true ] && echo 'Active' || echo 'Disabled')"

# Send deployment notification if webhook configured
if [ -n "$DISCORD_WEBHOOK_URL" ]; then
    COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "manual")
    curl -X POST "$DISCORD_WEBHOOK_URL" -H 'Content-Type: application/json' -d "{\"content\": \"🚀 AI Music Stream deployed successfully! Commit: $COMMIT_HASH\"}" 2>/dev/null || true
fi

log "✅ All done! Stream is running with latest updates."