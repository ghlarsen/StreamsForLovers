#!/bin/bash

# Health Check Script for AI Music Stream
# Monitors system health and triggers emergency mode if needed

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/var/log/ai-stream-health.log"
HEALTH_STATUS_FILE="$PROJECT_DIR/health_status.json"

# Thresholds
DISK_USAGE_WARNING=85
DISK_USAGE_CRITICAL=95
MEMORY_USAGE_WARNING=80
MEMORY_USAGE_CRITICAL=90
MAX_CONSECUTIVE_FAILURES=3

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Initialize failure counter file if not exists
FAILURE_COUNTER_FILE="$PROJECT_DIR/.health_failures"
if [ ! -f "$FAILURE_COUNTER_FILE" ]; then
    echo "0" > "$FAILURE_COUNTER_FILE"
fi

CONSECUTIVE_FAILURES=$(cat "$FAILURE_COUNTER_FILE")

cd "$PROJECT_DIR"

# 1. Check critical services
log "🏥 Running health check..."

STREAM_SERVICE_ACTIVE=$(systemctl is-active ai-music-stream 2>/dev/null || echo "inactive")
DISPLAY_SERVICE_ACTIVE=$(systemctl is-active virtual-display 2>/dev/null || echo "inactive")

CRITICAL_SERVICES_OK=true
if [ "$STREAM_SERVICE_ACTIVE" != "active" ]; then
    log "❌ AI Music Stream service is not active: $STREAM_SERVICE_ACTIVE"
    CRITICAL_SERVICES_OK=false
fi

if [ "$DISPLAY_SERVICE_ACTIVE" != "active" ]; then
    log "❌ Virtual Display service is not active: $DISPLAY_SERVICE_ACTIVE"
    CRITICAL_SERVICES_OK=false
fi

# 2. Check system resources
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
LOAD_AVERAGE=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')

RESOURCE_STATUS="OK"
if [ "$DISK_USAGE" -gt "$DISK_USAGE_CRITICAL" ]; then
    log "🚨 CRITICAL: Disk usage is ${DISK_USAGE}% (threshold: ${DISK_USAGE_CRITICAL}%)"
    RESOURCE_STATUS="CRITICAL"
elif [ "$DISK_USAGE" -gt "$DISK_USAGE_WARNING" ]; then
    log "⚠️  WARNING: Disk usage is ${DISK_USAGE}% (threshold: ${DISK_USAGE_WARNING}%)"
    RESOURCE_STATUS="WARNING"
fi

if [ "$MEMORY_USAGE" -gt "$MEMORY_USAGE_CRITICAL" ]; then
    log "🚨 CRITICAL: Memory usage is ${MEMORY_USAGE}% (threshold: ${MEMORY_USAGE_CRITICAL}%)"
    RESOURCE_STATUS="CRITICAL"
elif [ "$MEMORY_USAGE" -gt "$MEMORY_USAGE_WARNING" ]; then
    log "⚠️  WARNING: Memory usage is ${MEMORY_USAGE}% (threshold: ${MEMORY_USAGE_WARNING}%)"
    if [ "$RESOURCE_STATUS" = "OK" ]; then
        RESOURCE_STATUS="WARNING"
    fi
fi

# 3. Check network connectivity
NETWORK_OK=true
if ! ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    log "❌ Network connectivity failed"
    NETWORK_OK=false
fi

# 4. Check API connectivity (if service is running)
API_STATUS="N/A"
if [ "$STREAM_SERVICE_ACTIVE" = "active" ]; then
    # Test YouTube API
    if [ -n "$YOUTUBE_API_KEY" ]; then
        if command -v python3 &> /dev/null && [ -d "venv" ]; then
            source venv/bin/activate
            YOUTUBE_API_OK=$(python3 -c "
import os
import requests
try:
    api_key = os.getenv('YOUTUBE_API_KEY')
    response = requests.get(f'https://www.googleapis.com/youtube/v3/channels?part=id&mine=true&key={api_key}', timeout=5)
    print('OK' if response.status_code == 200 else 'FAILED')
except:
    print('FAILED')
" 2>/dev/null || echo "FAILED")
            
            if [ "$YOUTUBE_API_OK" = "OK" ]; then
                API_STATUS="OK"
            else
                API_STATUS="FAILED"
                log "❌ YouTube API connectivity failed"
            fi
        fi
    fi
fi

# 5. Check music generation queue (if service is running)
QUEUE_STATUS="N/A"
if [ "$STREAM_SERVICE_ACTIVE" = "active" ] && [ -d "venv" ]; then
    source venv/bin/activate
    QUEUE_SIZE=$(python3 -c "
import sys
sys.path.append('src')
try:
    from queue_manager import MusicQueueManager
    import asyncio
    
    async def check_queue():
        queue = MusicQueueManager()
        await queue.initialize()
        size = await queue.get_queue_size()
        return size
    
    size = asyncio.run(check_queue())
    print(size)
except:
    print('ERROR')
" 2>/dev/null || echo "ERROR")
    
    if [ "$QUEUE_SIZE" = "ERROR" ]; then
        QUEUE_STATUS="ERROR"
        log "❌ Music queue check failed"
    elif [ "$QUEUE_SIZE" -lt 2 ]; then
        QUEUE_STATUS="LOW"
        log "⚠️  WARNING: Music queue is low ($QUEUE_SIZE tracks)"
    else
        QUEUE_STATUS="OK"
    fi
fi

# 6. Calculate overall health status
OVERALL_HEALTH="HEALTHY"

if [ "$CRITICAL_SERVICES_OK" = "false" ] || [ "$RESOURCE_STATUS" = "CRITICAL" ] || [ "$NETWORK_OK" = "false" ] || [ "$API_STATUS" = "FAILED" ]; then
    OVERALL_HEALTH="CRITICAL"
elif [ "$RESOURCE_STATUS" = "WARNING" ] || [ "$QUEUE_STATUS" = "LOW" ] || [ "$QUEUE_STATUS" = "ERROR" ]; then
    OVERALL_HEALTH="WARNING"
fi

# 7. Handle consecutive failures
if [ "$OVERALL_HEALTH" = "CRITICAL" ]; then
    CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
    echo "$CONSECUTIVE_FAILURES" > "$FAILURE_COUNTER_FILE"
    
    log "🚨 CRITICAL health status detected (failure #${CONSECUTIVE_FAILURES}/${MAX_CONSECUTIVE_FAILURES})"
    
    if [ "$CONSECUTIVE_FAILURES" -ge "$MAX_CONSECUTIVE_FAILURES" ]; then
        log "🚨 Maximum consecutive failures reached - triggering emergency mode"
        
        # Trigger emergency mode
        "$SCRIPT_DIR/emergency_mode.sh" --reason "health_check_failure" --auto-recovery
        
        # Reset failure counter
        echo "0" > "$FAILURE_COUNTER_FILE"
        
        exit 0
    fi
else
    # Reset failure counter on successful health check
    if [ "$CONSECUTIVE_FAILURES" -gt 0 ]; then
        log "✅ Health recovered - resetting failure counter"
        echo "0" > "$FAILURE_COUNTER_FILE"
    fi
fi

# 8. Automatic maintenance tasks
if [ "$DISK_USAGE" -gt "$DISK_USAGE_WARNING" ]; then
    log "🧹 Running automatic cleanup due to high disk usage"
    
    # Clean old music files (keep last 24 hours)
    find music/ -name "*.mp3" -mtime +1 -delete 2>/dev/null || true
    find music/ -name "*.wav" -mtime +1 -delete 2>/dev/null || true
    
    # Clean old logs (keep last week)
    find logs/ -name "*.log" -mtime +7 -delete 2>/dev/null || true
    
    # Clean temporary files
    rm -f /tmp/ai_stream_* 2>/dev/null || true
    
    NEW_DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    SPACE_FREED=$((DISK_USAGE - NEW_DISK_USAGE))
    
    if [ "$SPACE_FREED" -gt 0 ]; then
        log "✅ Cleanup completed - freed ${SPACE_FREED}% disk space"
    fi
fi

# 9. Update health status file
cat > "$HEALTH_STATUS_FILE" << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
    "overall_health": "$OVERALL_HEALTH",
    "services": {
        "ai_music_stream": "$STREAM_SERVICE_ACTIVE",
        "virtual_display": "$DISPLAY_SERVICE_ACTIVE"
    },
    "resources": {
        "disk_usage": ${DISK_USAGE},
        "memory_usage": ${MEMORY_USAGE},
        "load_average": ${LOAD_AVERAGE}
    },
    "connectivity": {
        "network": $NETWORK_OK,
        "youtube_api": "$API_STATUS"
    },
    "queue": {
        "status": "$QUEUE_STATUS",
        "size": $([ "$QUEUE_SIZE" != "ERROR" ] && echo "$QUEUE_SIZE" || echo "null")
    },
    "consecutive_failures": $CONSECUTIVE_FAILURES,
    "emergency_mode": $([ -f "emergency_status.json" ] && echo "true" || echo "false")
}
EOF

# 10. Log health summary
log "📊 Health Check Summary:"
log "├── Overall Health: $OVERALL_HEALTH"
log "├── Services: Stream=$STREAM_SERVICE_ACTIVE, Display=$DISPLAY_SERVICE_ACTIVE"
log "├── Resources: Disk=${DISK_USAGE}%, Memory=${MEMORY_USAGE}%, Load=${LOAD_AVERAGE}"
log "├── Network: $([ $NETWORK_OK = true ] && echo "✅ OK" || echo "❌ Failed")"
log "├── APIs: $API_STATUS"
log "├── Queue: $QUEUE_STATUS $([ "$QUEUE_SIZE" != "ERROR" ] && echo "($QUEUE_SIZE tracks)" || echo "")"
log "└── Failures: ${CONSECUTIVE_FAILURES}/${MAX_CONSECUTIVE_FAILURES}"

# 11. Send alerts if needed
if [ "$OVERALL_HEALTH" = "CRITICAL" ] && [ -n "$DISCORD_WEBHOOK_URL" ]; then
    curl -X POST "$DISCORD_WEBHOOK_URL" -H 'Content-Type: application/json' -d "{
        \"content\": \"🚨 **CRITICAL HEALTH ALERT** 🚨\",
        \"embeds\": [{
            \"color\": 16711680,
            \"fields\": [
                {\"name\": \"Services\", \"value\": \"Stream: $STREAM_SERVICE_ACTIVE\\nDisplay: $DISPLAY_SERVICE_ACTIVE\", \"inline\": true},
                {\"name\": \"Resources\", \"value\": \"Disk: ${DISK_USAGE}%\\nMemory: ${MEMORY_USAGE}%\", \"inline\": true},
                {\"name\": \"Failures\", \"value\": \"${CONSECUTIVE_FAILURES}/${MAX_CONSECUTIVE_FAILURES}\", \"inline\": true}
            ],
            \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"
        }]
    }" 2>/dev/null || true
elif [ "$OVERALL_HEALTH" = "WARNING" ] && [ -n "$DISCORD_WEBHOOK_URL" ]; then
    # Send warning only once per hour to avoid spam
    LAST_WARNING_FILE="$PROJECT_DIR/.last_warning"
    CURRENT_HOUR=$(date +%Y%m%d%H)
    
    if [ ! -f "$LAST_WARNING_FILE" ] || [ "$(cat "$LAST_WARNING_FILE" 2>/dev/null)" != "$CURRENT_HOUR" ]; then
        echo "$CURRENT_HOUR" > "$LAST_WARNING_FILE"
        
        curl -X POST "$DISCORD_WEBHOOK_URL" -H 'Content-Type: application/json' -d "{
            \"content\": \"⚠️ Health Warning: AI Music Stream needs attention\",
            \"embeds\": [{
                \"color\": 16776960,
                \"fields\": [
                    {\"name\": \"Disk Usage\", \"value\": \"${DISK_USAGE}%\", \"inline\": true},
                    {\"name\": \"Memory Usage\", \"value\": \"${MEMORY_USAGE}%\", \"inline\": true},
                    {\"name\": \"Queue Status\", \"value\": \"$QUEUE_STATUS\", \"inline\": true}
                ]
            }]
        }" 2>/dev/null || true
    fi
fi

# 12. Exit with appropriate code
case $OVERALL_HEALTH in
    "HEALTHY")
        exit 0
        ;;
    "WARNING")
        exit 1
        ;;
    "CRITICAL")
        exit 2
        ;;
esac