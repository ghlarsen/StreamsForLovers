#!/bin/bash

# Emergency Mode Script for AI Music Stream
# Activates emergency fallback when main system fails

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
EMERGENCY_PLAYLIST_DURATION=8  # hours

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] EMERGENCY: $1"
}

log "🚨 EMERGENCY MODE ACTIVATION"
log "================================"

# Parse command line arguments
REASON="manual"
AUTO_RECOVERY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --reason)
            REASON="$2"
            shift 2
            ;;
        --auto-recovery)
            AUTO_RECOVERY=true
            shift
            ;;
        --help)
            echo "Emergency Mode Script for AI Music Stream"
            echo "Usage: $0 [--reason <reason>] [--auto-recovery]"
            echo ""
            echo "Options:"
            echo "  --reason <reason>    Specify the emergency reason"
            echo "  --auto-recovery      Enable automatic recovery attempts"
            echo "  --help              Show this help message"
            exit 0
            ;;
        *)
            log "❌ Unknown option: $1"
            exit 1
            ;;
    esac
done

log "🔍 Emergency triggered by: $REASON"
log "🤖 Auto-recovery: $([ $AUTO_RECOVERY = true ] && echo "ENABLED" || echo "DISABLED")"

cd "$PROJECT_DIR"

# 1. Immediate damage assessment
log "⚡ Running immediate system assessment..."

# Check critical services
STREAM_SERVICE_STATUS=$(systemctl is-active ai-music-stream 2>/dev/null || echo "failed")
DISPLAY_SERVICE_STATUS=$(systemctl is-active virtual-display 2>/dev/null || echo "failed")
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')

log "📊 System Status:"
log "├── Stream Service: $STREAM_SERVICE_STATUS"
log "├── Display Service: $DISPLAY_SERVICE_STATUS"
log "├── Disk Usage: ${DISK_USAGE}%"
log "└── Memory Usage: ${MEMORY_USAGE}%"

# 2. Determine emergency level
EMERGENCY_LEVEL="HIGH"

if [ "$STREAM_SERVICE_STATUS" = "active" ] && [ "$DISPLAY_SERVICE_STATUS" = "active" ]; then
    EMERGENCY_LEVEL="LOW"
elif [ "$STREAM_SERVICE_STATUS" = "active" ] || [ "$DISPLAY_SERVICE_STATUS" = "active" ]; then
    EMERGENCY_LEVEL="MEDIUM"
fi

log "🚨 Emergency Level: $EMERGENCY_LEVEL"

# 3. Activate emergency streaming based on level
case $EMERGENCY_LEVEL in
    "LOW")
        log "🟡 LOW EMERGENCY: Attempting component restart..."
        
        # Try to restart specific components
        if [ "$DISPLAY_SERVICE_STATUS" != "active" ]; then
            sudo systemctl restart virtual-display
            sleep 5
        fi
        
        # Test if recovery worked
        if systemctl is-active --quiet ai-music-stream && systemctl is-active --quiet virtual-display; then
            log "✅ LOW emergency resolved - services recovered"
            exit 0
        else
            log "⚠️  LOW emergency escalation - switching to MEDIUM"
            EMERGENCY_LEVEL="MEDIUM"
        fi
        ;;
        
    "MEDIUM"|"HIGH")
        log "🔴 $EMERGENCY_LEVEL EMERGENCY: Activating emergency streaming..."
        
        # 4. Create emergency YouTube premiere
        log "📺 Creating emergency YouTube premiere..."
        
        # Activate Python environment
        if [ -d "venv" ]; then
            source venv/bin/activate
        else
            log "⚠️  Virtual environment not found - using system Python"
        fi
        
        # Create emergency content
        python3 -c "
import sys
sys.path.append('src')
import os
import json
from datetime import datetime, timedelta

# Emergency configuration
emergency_config = {
    'duration_hours': $EMERGENCY_PLAYLIST_DURATION,
    'reason': '$REASON',
    'timestamp': datetime.now().isoformat(),
    'emergency_level': '$EMERGENCY_LEVEL',
    'auto_recovery': $AUTO_RECOVERY
}

# Save emergency state
with open('emergency_state.json', 'w') as f:
    json.dump(emergency_config, f, indent=2)

print(f'Emergency state saved - Duration: {emergency_config[\"duration_hours\"]} hours')
" 2>&1 | tee -a emergency.log
        
        # 5. Switch OBS to emergency mode
        log "🎬 Switching OBS to emergency mode..."
        
        # Try to switch OBS scene to emergency content
        python3 -c "
import sys
sys.path.append('src')
import asyncio
import json

async def activate_emergency_obs():
    try:
        from obs_controller import OBSController
        obs = OBSController()
        await obs.initialize()
        
        # Switch to emergency scene
        await obs.switch_scene('Emergency_Fallback')
        
        # Update emergency overlay
        emergency_info = {
            'reason': '$REASON',
            'estimated_recovery': '${EMERGENCY_PLAYLIST_DURATION} hours',
            'level': '$EMERGENCY_LEVEL'
        }
        
        await obs.update_emergency_overlay(emergency_info)
        print('✅ OBS switched to emergency mode')
        
    except Exception as e:
        print(f'⚠️  OBS emergency switch failed: {e}')
        
        # Fallback: Try to start emergency stream directly
        try:
            import subprocess
            subprocess.run(['obs', '--startstreaming', '--scene', 'Emergency_Fallback'], 
                         check=False, capture_output=True)
            print('✅ Emergency stream started via command line')
        except:
            print('❌ Could not start emergency stream')

asyncio.run(activate_emergency_obs())
" 2>&1 | tee -a emergency.log
        
        ;;
esac

# 6. Stop failed services to prevent resource conflicts
log "🛑 Stopping failed services..."

if [ "$STREAM_SERVICE_STATUS" != "active" ]; then
    systemctl stop ai-music-stream 2>/dev/null || true
    log "🔄 Stopped ai-music-stream service"
fi

# 7. Create emergency monitoring loop
if $AUTO_RECOVERY; then
    log "🤖 Starting automatic recovery monitoring..."
    
    # Create background recovery process
    cat > emergency_recovery.sh << 'EOF'
#!/bin/bash
RECOVERY_ATTEMPTS=0
MAX_ATTEMPTS=10
ATTEMPT_INTERVAL=300  # 5 minutes

while [ $RECOVERY_ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    sleep $ATTEMPT_INTERVAL
    
    echo "[$(date)] Recovery attempt $((RECOVERY_ATTEMPTS + 1))/$MAX_ATTEMPTS"
    
    # Try to restart services
    sudo systemctl start virtual-display
    sleep 10
    sudo systemctl start ai-music-stream
    sleep 20
    
    # Check if recovery successful
    if systemctl is-active --quiet ai-music-stream && systemctl is-active --quiet virtual-display; then
        echo "[$(date)] ✅ RECOVERY SUCCESSFUL!"
        
        # Exit emergency mode
        python3 -c "
import sys
sys.path.append('src')
from obs_controller import OBSController
import asyncio

async def exit_emergency():
    obs = OBSController()
    await obs.initialize()
    await obs.exit_maintenance_mode()

asyncio.run(exit_emergency())
" 2>/dev/null || true
        
        # Clean up emergency state
        rm -f emergency_state.json
        rm -f emergency_recovery.sh
        
        # Send recovery notification
        if [ -n "$DISCORD_WEBHOOK_URL" ]; then
            curl -X POST "$DISCORD_WEBHOOK_URL" -H 'Content-Type: application/json' \
                 -d '{"content": "✅ AI Music Stream recovered automatically from emergency mode!"}' 2>/dev/null || true
        fi
        
        exit 0
    fi
    
    RECOVERY_ATTEMPTS=$((RECOVERY_ATTEMPTS + 1))
    echo "[$(date)] Recovery attempt failed, waiting for next attempt..."
done

echo "[$(date)] ❌ Maximum recovery attempts reached - manual intervention required"
EOF
    
    chmod +x emergency_recovery.sh
    nohup ./emergency_recovery.sh > emergency_recovery.log 2>&1 &
    RECOVERY_PID=$!
    
    echo $RECOVERY_PID > emergency_recovery.pid
    log "🤖 Auto-recovery process started (PID: $RECOVERY_PID)"
fi

# 8. Send emergency notifications
log "📢 Sending emergency notifications..."

# Discord notification
if [ -n "$DISCORD_WEBHOOK_URL" ]; then
    curl -X POST "$DISCORD_WEBHOOK_URL" -H 'Content-Type: application/json' -d "{
        \"content\": \"🚨 **EMERGENCY MODE ACTIVATED** 🚨\",
        \"embeds\": [{
            \"color\": 16711680,
            \"fields\": [
                {\"name\": \"Reason\", \"value\": \"$REASON\", \"inline\": true},
                {\"name\": \"Level\", \"value\": \"$EMERGENCY_LEVEL\", \"inline\": true},
                {\"name\": \"Auto Recovery\", \"value\": \"$([ $AUTO_RECOVERY = true ] && echo "Enabled" || echo "Disabled")\", \"inline\": true},
                {\"name\": \"Emergency Duration\", \"value\": \"${EMERGENCY_PLAYLIST_DURATION} hours\", \"inline\": true}
            ],
            \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"
        }]
    }" 2>/dev/null || log "⚠️  Discord notification failed"
fi

# Email notification (if configured)
if [ -n "$EMERGENCY_EMAIL" ] && command -v mail &> /dev/null; then
    echo "Emergency Mode Activated: $REASON (Level: $EMERGENCY_LEVEL)" | \
        mail -s "🚨 AI Music Stream Emergency" "$EMERGENCY_EMAIL" 2>/dev/null || true
fi

# 9. Create emergency status file
cat > emergency_status.json << EOF
{
    "emergency_active": true,
    "activation_time": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
    "reason": "$REASON",
    "level": "$EMERGENCY_LEVEL",
    "auto_recovery": $AUTO_RECOVERY,
    "estimated_duration_hours": $EMERGENCY_PLAYLIST_DURATION,
    "recovery_pid": $([ -f emergency_recovery.pid ] && cat emergency_recovery.pid || echo "null"),
    "system_status": {
        "stream_service": "$STREAM_SERVICE_STATUS",
        "display_service": "$DISPLAY_SERVICE_STATUS",
        "disk_usage": "${DISK_USAGE}%",
        "memory_usage": "${MEMORY_USAGE}%"
    }
}
EOF

log "📋 Emergency status saved to emergency_status.json"

# 10. Final emergency summary
log "🚨 EMERGENCY MODE ACTIVATION COMPLETE"
log "======================================"
log "📊 Summary:"
log "├── Emergency Level: $EMERGENCY_LEVEL"
log "├── Reason: $REASON"
log "├── Duration: ${EMERGENCY_PLAYLIST_DURATION} hours"
log "├── Auto Recovery: $([ $AUTO_RECOVERY = true ] && echo "ACTIVE" || echo "MANUAL")"
log "├── Stream Status: Emergency content active"
log "└── Next Action: $([ $AUTO_RECOVERY = true ] && echo "Wait for auto-recovery" || echo "Manual intervention required")"

# 11. Emergency instructions
log ""
log "🆘 EMERGENCY INSTRUCTIONS:"
log "=========================="
log "1. Stream is now showing emergency content to viewers"
log "2. Check emergency.log for detailed error information"
log "3. Monitor system status with: systemctl status ai-music-stream"
log "4. To manually exit emergency mode: ./scripts/exit_emergency.sh"
log "5. For immediate help: tail -f emergency.log"

if $AUTO_RECOVERY; then
    log "6. Auto-recovery monitoring active - check emergency_recovery.log"
    log "7. To stop auto-recovery: kill $(cat emergency_recovery.pid 2>/dev/null || echo 'PID-NOT-FOUND')"
fi

log ""
log "🎵 Viewers will continue to hear emergency music content"
log "⏰ Emergency mode will last approximately ${EMERGENCY_PLAYLIST_DURATION} hours"
log "📞 Contact system administrator if manual intervention is needed"

exit 0