#!/bin/bash

# Safe Server Reboot Script for 24/7 AI Music Stream
# Ensures stream continuity during server maintenance

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
EMERGENCY_DURATION_HOURS=4

echo "🔄 Initiating safe server reboot for AI Music Stream..."
echo "============================================================"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if we're running as root or with sudo
if [[ $EUID -eq 0 ]]; then
   log "⚠️  Running as root - this is not recommended for production"
fi

# 1. Health check current stream status
log "🏥 Checking current stream health..."
if systemctl is-active --quiet ai-music-stream; then
    STREAM_RUNNING=true
    log "✅ Stream is currently active"
else
    STREAM_RUNNING=false
    log "⚠️  Stream is not running - safe to reboot without preparation"
fi

# 2. Generate emergency content if stream is running
if $STREAM_RUNNING; then
    log "🎵 Generating emergency content buffer (${EMERGENCY_DURATION_HOURS} hours)..."
    
    cd "$PROJECT_DIR"
    source venv/bin/activate
    
    # Build emergency playlist
    python3 -c "
import sys
sys.path.append('src')
from emergency_buffer import EmergencyBuffer
buffer = EmergencyBuffer()
buffer.create_emergency_playlist(hours=${EMERGENCY_DURATION_HOURS})
print('Emergency playlist created successfully')
"
    
    if [ $? -eq 0 ]; then
        log "✅ Emergency content generated successfully"
    else
        log "❌ Failed to generate emergency content - aborting reboot"
        exit 1
    fi
fi

# 3. Enter maintenance mode
if $STREAM_RUNNING; then
    log "🔧 Entering maintenance mode..."
    
    # Switch OBS to maintenance scene
    python3 -c "
import sys
sys.path.append('src')
from obs_controller import OBSController
import asyncio

async def enter_maintenance():
    obs = OBSController()
    await obs.initialize()
    await obs.enter_maintenance_mode()
    print('Maintenance mode activated')

asyncio.run(enter_maintenance())
"
    
    if [ $? -eq 0 ]; then
        log "✅ Maintenance mode activated"
        # Give OBS time to switch scenes
        sleep 10
    else
        log "⚠️  Could not activate maintenance mode - continuing anyway"
    fi
fi

# 4. Create reboot marker for post-boot recovery
log "📝 Creating reboot recovery marker..."
echo "$(date)" > /tmp/ai_stream_reboot_marker
echo "STREAM_WAS_RUNNING=$STREAM_RUNNING" >> /tmp/ai_stream_reboot_marker
echo "REBOOT_INITIATED_BY=$(whoami)" >> /tmp/ai_stream_reboot_marker

# 5. Gracefully stop services
log "⏹️  Gracefully stopping services..."

if systemctl is-active --quiet ai-music-stream; then
    systemctl stop ai-music-stream
    log "✅ AI Music Stream service stopped"
fi

if systemctl is-active --quiet virtual-display; then
    systemctl stop virtual-display
    log "✅ Virtual display service stopped"
fi

# 6. Wait a moment for clean shutdown
log "⏳ Waiting for clean service shutdown..."
sleep 5

# 7. Final checks before reboot
log "🔍 Pre-reboot system checks..."

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    log "⚠️  Warning: Disk usage is ${DISK_USAGE}% - may need cleanup after reboot"
fi

# Check memory
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
log "💾 Memory usage: ${MEMORY_USAGE}%"

# 8. Schedule post-reboot recovery
log "📋 Scheduling post-reboot recovery..."

# Create systemd service for post-boot recovery
sudo tee /etc/systemd/system/ai-stream-recovery.service > /dev/null <<EOF
[Unit]
Description=AI Music Stream Post-Reboot Recovery
After=network.target multi-user.target

[Service]
Type=oneshot
User=$(whoami)
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/scripts/post_reboot_recovery.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable ai-stream-recovery.service
log "✅ Post-reboot recovery service scheduled"

# 9. Final notification
if $STREAM_RUNNING; then
    log "🚨 IMPORTANT: Stream is now in maintenance mode"
    log "📺 Viewers will see emergency content during reboot"
    log "⏱️  Emergency content duration: ${EMERGENCY_DURATION_HOURS} hours"
    log "🔄 Automatic recovery will start after reboot"
fi

log "🎯 Pre-reboot checklist complete!"
log "💾 Emergency content: $([ $STREAM_RUNNING = true ] && echo "✅ Ready" || echo "N/A")"
log "🔧 Maintenance mode: $([ $STREAM_RUNNING = true ] && echo "✅ Active" || echo "N/A")"
log "📋 Recovery scheduled: ✅ Yes"

# 10. Countdown before reboot
log "⏰ Starting reboot countdown..."
for i in {10..1}; do
    echo "Rebooting in $i seconds... (Press Ctrl+C to cancel)"
    sleep 1
done

# 11. Perform the reboot
log "🔄 Initiating system reboot now..."
sudo reboot

# This script ends here - post_reboot_recovery.sh will run after restart