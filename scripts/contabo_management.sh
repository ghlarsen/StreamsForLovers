#!/bin/bash

# Contabo CLI Management Script for AI Music Streaming Platform
# Automates server provisioning and management across scaling stages

set -e

# Configuration
CONTABO_CLI_VERSION="1.4.3"  # Update as needed
CONTABO_REGION="EU"  # Hub Europe
CONTABO_PRODUCT_ID="V45"  # Cloud VPS 10 SSD (€4.02/month)
CONTABO_IMAGE_ID="ubuntu-22.04"  # Ubuntu 22.04 LTS

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Install Contabo CLI
install_contabo_cli() {
    log "📦 Installing Contabo CLI..."
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="darwin"
        ARCH="amd64"
        if [[ $(uname -m) == "arm64" ]]; then
            ARCH="arm64"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        ARCH="amd64"
    else
        log "❌ Unsupported OS: $OSTYPE"
        exit 1
    fi
    
    # Download and install
    DOWNLOAD_URL="https://github.com/contabo/cntb/releases/download/v${CONTABO_CLI_VERSION}/cntb_${CONTABO_CLI_VERSION}_${OS}_${ARCH}.tar.gz"
    
    curl -LO "$DOWNLOAD_URL"
    tar -xzf "cntb_${CONTABO_CLI_VERSION}_${OS}_${ARCH}.tar.gz"
    
    # Install to system PATH
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sudo mv cntb /usr/local/bin/
    else
        sudo mv cntb /usr/bin/
    fi
    
    # Cleanup
    rm "cntb_${CONTABO_CLI_VERSION}_${OS}_${ARCH}.tar.gz"
    
    log "✅ Contabo CLI installed successfully"
    cntb version
}

# Configure Contabo credentials
configure_credentials() {
    log "🔐 Configuring Contabo credentials..."
    echo "Please provide your Contabo API credentials from Customer Control Panel:"
    echo "Go to: https://my.contabo.com/api/details"
    
    read -p "Client ID: " CLIENT_ID
    read -p "Client Secret: " CLIENT_SECRET
    read -p "API User: " API_USER
    read -sp "API Password: " API_PASSWORD
    echo
    
    cntb config set-credentials \
        --oauth2-clientid="$CLIENT_ID" \
        --oauth2-client-secret="$CLIENT_SECRET" \
        --oauth2-user="$API_USER" \
        --oauth2-password="$API_PASSWORD"
    
    log "✅ Credentials configured"
}

# List available images and products
list_available_options() {
    log "📋 Available images and products:"
    
    echo "=== Available Images ==="
    cntb get images | head -20
    
    echo "=== Available Products ==="
    cntb get products | head -20
}

# Create a new streaming server
create_streaming_server() {
    local SERVER_NAME="$1"
    local STAGE="$2"
    
    if [ -z "$SERVER_NAME" ] || [ -z "$STAGE" ]; then
        echo "Usage: create_streaming_server <name> <stage>"
        echo "Example: create_streaming_server cityPop-anime 1"
        return 1
    fi
    
    log "🚀 Creating streaming server: $SERVER_NAME (Stage $STAGE)"
    
    # Generate cloud-init script for automatic setup
    cat > /tmp/cloud-init-${SERVER_NAME}.yaml << EOF
#cloud-config
hostname: ${SERVER_NAME}
users:
  - name: aistream
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa YOUR_PUBLIC_KEY_HERE  # Replace with your SSH key

packages:
  - curl
  - wget
  - git
  - python3
  - python3-pip
  - python3-venv
  - nodejs
  - npm
  - ffmpeg
  - xvfb
  - pulseaudio
  - alsa-utils
  - software-properties-common

runcmd:
  - add-apt-repository ppa:obsproject/obs-studio -y
  - apt update
  - apt install -y obs-studio
  - mkdir -p /opt/ai-music-stream
  - chown aistream:aistream /opt/ai-music-stream
  - systemctl enable ssh
  - ufw allow 22
  - ufw allow 1935
  - ufw --force enable
  
write_files:
  - path: /etc/motd
    content: |
      Welcome to AI Music Stream Server: ${SERVER_NAME}
      Stage: $STAGE
      
      Quick commands:
      - cd /opt/ai-music-stream
      - systemctl status ai-music-stream
      - journalctl -u ai-music-stream -f
EOF

    # Create the instance
    INSTANCE_ID=$(cntb create instance \
        --imageId "$CONTABO_IMAGE_ID" \
        --productId "$CONTABO_PRODUCT_ID" \
        --region "$CONTABO_REGION" \
        --displayName "$SERVER_NAME" \
        --userData "$(cat /tmp/cloud-init-${SERVER_NAME}.yaml)" \
        --sshKeys "$(cat ~/.ssh/id_rsa.pub 2>/dev/null || echo '')" \
        --format json | jq -r '.instanceId')
    
    if [ "$INSTANCE_ID" != "null" ] && [ -n "$INSTANCE_ID" ]; then
        log "✅ Server created successfully: $SERVER_NAME (ID: $INSTANCE_ID)"
        
        # Save instance info
        echo "$INSTANCE_ID,$SERVER_NAME,$STAGE,$(date)" >> ~/.cntb_instances.csv
        
        # Wait for server to be ready
        log "⏳ Waiting for server to be ready..."
        while true; do
            STATUS=$(cntb get instances --instanceId "$INSTANCE_ID" --format json | jq -r '.data[0].status')
            if [ "$STATUS" = "running" ]; then
                break
            fi
            echo "Status: $STATUS - waiting..."
            sleep 30
        done
        
        # Get IP address
        IP_ADDRESS=$(cntb get instances --instanceId "$INSTANCE_ID" --format json | jq -r '.data[0].ipConfig.v4.ip')
        log "🌍 Server ready at IP: $IP_ADDRESS"
        
        echo "Server Details:"
        echo "  Name: $SERVER_NAME"
        echo "  ID: $INSTANCE_ID"
        echo "  IP: $IP_ADDRESS"
        echo "  Stage: $STAGE"
        
        return 0
    else
        log "❌ Failed to create server"
        return 1
    fi
}

# Stage-specific server provisioning
provision_stage_1() {
    log "🎵 Provisioning Stage 1: Single Stream (City Pop Anime)"
    create_streaming_server "cityPop-anime" "1"
}

provision_stage_2() {
    log "🚀 Provisioning Stage 2: Dual Stream"
    create_streaming_server "neon-synthwave" "2"
    echo "Note: Use existing cityPop-anime server as primary"
}

provision_stage_3() {
    log "⭐ Provisioning Stage 3: Quad Stream"
    create_streaming_server "cosmic-ambient" "3"
    create_streaming_server "fitness-beats" "3"
    
    # Also need orchestration server
    create_orchestration_server "3"
}

provision_stage_4() {
    log "👑 Provisioning Stage 4: Full Platform"
    create_streaming_server "noir-jazz" "4"
    create_streaming_server "desert-country" "4"
    create_streaming_server "intimate-vibes" "4"
    
    # Upgrade orchestration server
    create_orchestration_server "4"
}

create_orchestration_server() {
    local STAGE="$1"
    
    # Use larger instance for orchestration
    CONTABO_PRODUCT_ID="V92"  # Larger instance for orchestration
    create_streaming_server "orchestration-master" "$STAGE"
    CONTABO_PRODUCT_ID="V45"  # Reset to default
}

# List all managed instances
list_instances() {
    log "📊 Current AI Music Stream instances:"
    
    if [ -f ~/.cntb_instances.csv ]; then
        echo "ID,Name,Stage,Created" 
        cat ~/.cntb_instances.csv
        echo ""
    fi
    
    echo "=== Live Contabo Instances ==="
    cntb get instances --format table
}

# Stop instances (cost saving)
stop_instances() {
    local STAGE="$1"
    
    if [ -z "$STAGE" ]; then
        echo "Usage: stop_instances <stage>"
        echo "Example: stop_instances 2"
        return 1
    fi
    
    log "⏹️ Stopping Stage $STAGE instances..."
    
    if [ -f ~/.cntb_instances.csv ]; then
        grep ",$STAGE," ~/.cntb_instances.csv | while IFS=, read -r INSTANCE_ID NAME INSTANCE_STAGE CREATED; do
            log "Stopping $NAME ($INSTANCE_ID)..."
            cntb stop instance "$INSTANCE_ID"
        done
    fi
}

# Start instances
start_instances() {
    local STAGE="$1"
    
    if [ -z "$STAGE" ]; then
        echo "Usage: start_instances <stage>"
        echo "Example: start_instances 2"
        return 1
    fi
    
    log "▶️ Starting Stage $STAGE instances..."
    
    if [ -f ~/.cntb_instances.csv ]; then
        grep ",$STAGE," ~/.cntb_instances.csv | while IFS=, read -r INSTANCE_ID NAME INSTANCE_STAGE CREATED; do
            log "Starting $NAME ($INSTANCE_ID)..."
            cntb start instance "$INSTANCE_ID"
        done
    fi
}

# Delete instances (careful!)
delete_instances() {
    local STAGE="$1"
    
    if [ -z "$STAGE" ]; then
        echo "Usage: delete_instances <stage>"
        echo "Example: delete_instances 2"
        return 1
    fi
    
    log "🗑️ WARNING: This will DELETE Stage $STAGE instances!"
    read -p "Are you sure? Type 'DELETE' to confirm: " CONFIRM
    
    if [ "$CONFIRM" != "DELETE" ]; then
        log "❌ Deletion cancelled"
        return 1
    fi
    
    if [ -f ~/.cntb_instances.csv ]; then
        grep ",$STAGE," ~/.cntb_instances.csv | while IFS=, read -r INSTANCE_ID NAME INSTANCE_STAGE CREATED; do
            log "Deleting $NAME ($INSTANCE_ID)..."
            cntb delete instance "$INSTANCE_ID"
        done
        
        # Remove from tracking file
        grep -v ",$STAGE," ~/.cntb_instances.csv > ~/.cntb_instances_tmp.csv || true
        mv ~/.cntb_instances_tmp.csv ~/.cntb_instances.csv
    fi
}

# Cost calculator
calculate_costs() {
    log "💰 Monthly cost calculation:"
    
    echo "Current instances by stage:"
    if [ -f ~/.cntb_instances.csv ]; then
        for STAGE in 1 2 3 4; do
            COUNT=$(grep ",$STAGE," ~/.cntb_instances.csv | wc -l)
            if [ "$COUNT" -gt 0 ]; then
                COST=$(echo "$COUNT * 4.02" | bc)
                echo "  Stage $STAGE: $COUNT servers × €4.02 = €$COST/month"
            fi
        done
    fi
}

# Main menu
case "${1:-help}" in
    "install")
        install_contabo_cli
        ;;
    "configure")
        configure_credentials
        ;;
    "list-options")
        list_available_options
        ;;
    "provision-stage-1")
        provision_stage_1
        ;;
    "provision-stage-2")
        provision_stage_2
        ;;
    "provision-stage-3")
        provision_stage_3
        ;;
    "provision-stage-4")
        provision_stage_4
        ;;
    "list")
        list_instances
        ;;
    "stop")
        stop_instances "$2"
        ;;
    "start")
        start_instances "$2"
        ;;
    "delete")
        delete_instances "$2"
        ;;
    "costs")
        calculate_costs
        ;;
    "help"|*)
        echo "Contabo Management Script for AI Music Streaming Platform"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Setup Commands:"
        echo "  install           Install Contabo CLI"
        echo "  configure         Configure API credentials"
        echo "  list-options      Show available images and products"
        echo ""
        echo "Provisioning Commands:"
        echo "  provision-stage-1 Provision Stage 1 servers (1 server)"
        echo "  provision-stage-2 Provision Stage 2 servers (add 1 server)"
        echo "  provision-stage-3 Provision Stage 3 servers (add 2 servers + orchestration)"
        echo "  provision-stage-4 Provision Stage 4 servers (add 3 servers + upgrade orchestration)"
        echo ""
        echo "Management Commands:"
        echo "  list              List all managed instances"
        echo "  stop <stage>      Stop instances for specific stage"
        echo "  start <stage>     Start instances for specific stage"
        echo "  delete <stage>    Delete instances for specific stage (CAREFUL!)"
        echo "  costs             Calculate current monthly costs"
        echo ""
        echo "Examples:"
        echo "  $0 install"
        echo "  $0 configure"
        echo "  $0 provision-stage-1"
        echo "  $0 stop 2"
        echo "  $0 start 2"
        ;;
esac