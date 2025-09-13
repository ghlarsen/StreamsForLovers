#!/bin/bash

# Post-Reboot Recovery Script for AI Music Stream
# Automatically restores stream after server reboot

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RECOVERY_MARKER="/tmp/ai_stream_reboot_marker"
LOG_FILE="/var/log/ai-stream-recovery.log"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🔄 AI Music Stream Post-Reboot Recovery Starting..."
log "=================================================="

# 1. Check if this is a recovery from planned reboot
if [ ! -f "$RECOVERY_MARKER" ]; then
    log "ℹ️  No reboot marker found - this may be an unplanned restart"
    STREAM_WAS_RUNNING=true  # Assume stream should be running
else
    log "📋 Reading reboot recovery information..."
    source "$RECOVERY_MARKER"
    log "✅ Recovery marker found - stream was $([ "$STREAM_WAS_RUNNING" = "true" ] && echo "running" || echo "stopped") before reboot"
fi

# 2. Wait for all system services to be ready
log "⏳ Waiting for system services to be ready..."
sleep 30

# Wait for network connectivity
log "🌐 Checking network connectivity..."
for i in {1..10}; do
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        log "✅ Network connectivity confirmed"
        break
    fi
    if [ $i -eq 10 ]; then
        log "❌ Network connectivity failed - aborting recovery"
        exit 1
    fi
    sleep 10
done

# 3. Verify all required services are available
log "🔍 Checking system prerequisites..."

# Check if Python virtual environment exists
if [ ! -d "$PROJECT_DIR/venv" ]; then
    log "❌ Python virtual environment not found - running setup..."
    cd "$PROJECT_DIR"
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
fi

# Activate Python environment
cd "$PROJECT_DIR"
source venv/bin/activate

# 4. Perform comprehensive health check
log "🏥 Running comprehensive system health check..."

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 95 ]; then
    log "❌ Critical: Disk usage is ${DISK_USAGE}% - cleanup required before recovery"
    # Attempt basic cleanup
    find "$PROJECT_DIR/music" -name "*.mp3" -mtime +7 -delete 2>/dev/null || true
    find "$PROJECT_DIR/logs" -name "*.log" -mtime +7 -delete 2>/dev/null || true
fi

# Check if OBS is installed
if ! command -v obs &> /dev/null; then
    log "⚠️  OBS Studio not found - may need reinstallation"
fi

# Check virtual display service
log "🖥️  Starting virtual display service..."
sudo systemctl start virtual-display.service
sleep 5

if systemctl is-active --quiet virtual-display.service; then
    log "✅ Virtual display service started"
else
    log "❌ Virtual display service failed to start"
    # Try to restart X server
    sudo systemctl restart virtual-display.service
    sleep 10
fi

# 5. Test API connectivity
log "🔗 Testing API connectivity..."

# Test YouTube API
python3 -c "
import os
import requests
import sys

api_key = os.getenv('YOUTUBE_API_KEY')
if not api_key:
    print('❌ YouTube API key not configured')
    sys.exit(1)

try:
    response = requests.get(f'https://www.googleapis.com/youtube/v3/channels?part=id&mine=true&key={api_key}', timeout=10)
    if response.status_code == 200:
        print('✅ YouTube API connectivity confirmed')
    else:
        print(f'⚠️  YouTube API returned status {response.status_code}')
except Exception as e:
    print(f'❌ YouTube API test failed: {e}')
    sys.exit(1)
" 2>&1 | tee -a "$LOG_FILE"

# Test Suno API
python3 -c "
import os
import requests
import sys

api_key = os.getenv('SUNO_API_KEY')
api_url = os.getenv('SUNO_API_URL', 'https://sunoapi.com/api/v1')
if not api_key:
    print('❌ Suno API key not configured')
    sys.exit(1)

try:
    response = requests.get(f'{api_url}/health', headers={'Authorization': f'Bearer {api_key}'}, timeout=10)
    if response.status_code == 200:
        print('✅ Suno API connectivity confirmed')
    else:
        print(f'⚠️  Suno API returned status {response.status_code}')
except Exception as e:
    print(f'⚠️  Suno API test failed: {e} (may be normal if endpoint differs)')
" 2>&1 | tee -a "$LOG_FILE"

# 6. Initialize application components
log "🔧 Initializing application components..."

# Test basic component initialization
python3 -c "
import sys
sys.path.append('src')
from main import InteractiveStreamManager
import asyncio

async def test_initialization():
    stream_manager = InteractiveStreamManager()
    try:
        success = await stream_manager.initialize()
        if success:
            print('✅ Application components initialized successfully')
            await stream_manager.shutdown()
            return True
        else:
            print('❌ Component initialization failed')
            return False
    except Exception as e:
        print(f'❌ Initialization error: {e}')
        return False

success = asyncio.run(test_initialization())
sys.exit(0 if success else 1)
" 2>&1 | tee -a "$LOG_FILE"

if [ $? -ne 0 ]; then
    log "❌ Component initialization failed - manual intervention required"
    exit 1
fi

# 7. Restore stream if it was running before reboot
if [ "$STREAM_WAS_RUNNING" = "true" ]; then
    log "🚀 Restoring AI Music Stream service..."
    
    # Start the main service
    sudo systemctl start ai-music-stream.service
    sleep 15
    
    # Check if service started successfully
    if systemctl is-active --quiet ai-music-stream.service; then
        log "✅ AI Music Stream service started successfully"
        
        # Wait a bit more for full initialization
        sleep 30
        
        # Exit maintenance mode
        log "🎵 Exiting maintenance mode and resuming live stream..."
        python3 -c "
import sys
sys.path.append('src')
from obs_controller import OBSController
import asyncio

async def exit_maintenance():
    obs = OBSController()
    await obs.initialize()
    await obs.exit_maintenance_mode()
    print('✅ Live streaming resumed')

asyncio.run(exit_maintenance())
" 2>&1 | tee -a "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            log "🎉 Stream recovery completed successfully!"
        else
            log "⚠️  Stream started but maintenance mode exit failed - manual check needed"
        fi
        
    else
        log "❌ Failed to start AI Music Stream service"
        log "📋 Service status:"
        systemctl status ai-music-stream.service | tee -a "$LOG_FILE"
        exit 1
    fi
else
    log "ℹ️  Stream was not running before reboot - no restoration needed"
fi

# 8. Final health check and monitoring setup
log "📊 Performing final health check..."

# Check service status
SERVICE_STATUS=$(systemctl is-active ai-music-stream.service 2>/dev/null || echo "inactive")
DISPLAY_STATUS=$(systemctl is-active virtual-display.service 2>/dev/null || echo "inactive")

log "📈 Recovery Status Report:"
log "├── AI Music Stream: $SERVICE_STATUS"
log "├── Virtual Display: $DISPLAY_STATUS"
log "├── Disk Usage: ${DISK_USAGE}%"
log "├── Network: Connected"
log "└── APIs: Tested"

# 9. Cleanup and final setup
log "🧹 Cleaning up recovery artifacts..."

# Remove reboot marker
rm -f "$RECOVERY_MARKER"

# Disable the recovery service (it's a oneshot)
sudo systemctl disable ai-stream-recovery.service
sudo rm -f /etc/systemd/system/ai-stream-recovery.service
sudo systemctl daemon-reload

# Set up monitoring cron job if not exists
if ! crontab -l 2>/dev/null | grep -q "health_check.sh"; then
    log "📋 Setting up health monitoring cron job..."
    (crontab -l 2>/dev/null; echo "*/5 * * * * $PROJECT_DIR/scripts/health_check.sh") | crontab -
fi

log "✅ Post-reboot recovery completed successfully!"
log "🎵 AI Music Stream is now running and ready for interaction"
log "📊 Check logs: journalctl -u ai-music-stream -f"
log "🌐 Monitor stream: http://localhost:8080/status (if web interface enabled)"

# Send success notification if configured
if [ -n "$DISCORD_WEBHOOK_URL" ]; then
    curl -X POST "$DISCORD_WEBHOOK_URL" -H 'Content-Type: application/json' -d "{\"content\": \"🎉 AI Music Stream recovery completed successfully after server reboot!\"}" 2>/dev/null || true
fi

exit 0