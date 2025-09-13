#!/bin/bash

# SSH Connection Diagnostic and Repair Script
# For Contabo server 161.97.116.47

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== SSH Connection Diagnostic & Repair ===${NC}"
echo "Server: 161.97.116.47 (ai-stream-server)"
echo "Date: $(date)"
echo

# Function to print section headers
section() {
    echo
    echo -e "${YELLOW}$1${NC}"
    echo "----------------------------------------"
}

# Function to check command success
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        return 1
    fi
}

section "1. LOCAL SSH KEY VERIFICATION"

# Check if private key exists
if [ -f ~/.ssh/deploy_ai_stream ]; then
    echo -e "${GREEN}✓ Private key exists${NC}"
    
    # Check private key permissions
    perms=$(stat -f "%OLp" ~/.ssh/deploy_ai_stream 2>/dev/null || stat -c "%a" ~/.ssh/deploy_ai_stream 2>/dev/null)
    if [ "$perms" = "600" ]; then
        echo -e "${GREEN}✓ Private key permissions: 600${NC}"
    else
        echo -e "${RED}✗ Private key permissions: $perms (should be 600)${NC}"
        echo "  Fixing..."
        chmod 600 ~/.ssh/deploy_ai_stream
        check_result "Private key permissions fixed"
    fi
    
    # Verify key format
    ssh-keygen -y -f ~/.ssh/deploy_ai_stream > /dev/null 2>&1
    check_result "Private key format valid"
else
    echo -e "${RED}✗ Private key not found at ~/.ssh/deploy_ai_stream${NC}"
    exit 1
fi

# Check if public key exists
if [ -f ~/.ssh/deploy_ai_stream.pub ]; then
    echo -e "${GREEN}✓ Public key exists${NC}"
    
    # Display fingerprint
    echo -n "  Fingerprint: "
    ssh-keygen -l -f ~/.ssh/deploy_ai_stream.pub | cut -d' ' -f2
    
    # Check public key format
    if grep -q "^ssh-rsa " ~/.ssh/deploy_ai_stream.pub; then
        echo -e "${GREEN}✓ Public key format: ssh-rsa${NC}"
    elif grep -q "^ssh-ed25519 " ~/.ssh/deploy_ai_stream.pub; then
        echo -e "${GREEN}✓ Public key format: ssh-ed25519${NC}"
    else
        echo -e "${RED}✗ Unknown public key format${NC}"
    fi
else
    echo -e "${RED}✗ Public key not found${NC}"
    echo "  Generating from private key..."
    ssh-keygen -y -f ~/.ssh/deploy_ai_stream > ~/.ssh/deploy_ai_stream.pub
    check_result "Public key generated"
fi

section "2. SSH AGENT STATUS"

# Check if ssh-agent is running
if ssh-add -l > /dev/null 2>&1; then
    echo -e "${GREEN}✓ SSH agent is running${NC}"
    
    # Check if our key is loaded
    if ssh-add -l | grep -q "deploy_ai_stream"; then
        echo -e "${GREEN}✓ Key is loaded in agent${NC}"
    else
        echo -e "${YELLOW}⚠ Key not in agent, adding...${NC}"
        ssh-add ~/.ssh/deploy_ai_stream
        check_result "Key added to agent"
    fi
else
    echo -e "${RED}✗ SSH agent not running${NC}"
    echo "  Starting agent..."
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/deploy_ai_stream
    check_result "Agent started and key added"
fi

section "3. SSH CONFIG CHECK"

if [ -f ~/.ssh/config ]; then
    echo -e "${GREEN}✓ SSH config exists${NC}"
    
    # Check if ai-stream-server is configured
    if grep -q "Host ai-stream-server" ~/.ssh/config; then
        echo -e "${GREEN}✓ ai-stream-server alias configured${NC}"
        echo "  Configuration:"
        grep -A 4 "Host ai-stream-server" ~/.ssh/config | sed 's/^/    /'
    else
        echo -e "${YELLOW}⚠ ai-stream-server not in config${NC}"
        echo "  Adding configuration..."
        cat >> ~/.ssh/config << EOF

Host ai-stream-server
    HostName 161.97.116.47
    User root
    IdentityFile ~/.ssh/deploy_ai_stream
    IdentitiesOnly yes
EOF
        check_result "Configuration added"
    fi
else
    echo -e "${YELLOW}⚠ SSH config not found, creating...${NC}"
    cat > ~/.ssh/config << EOF
Host ai-stream-server
    HostName 161.97.116.47
    User root
    IdentityFile ~/.ssh/deploy_ai_stream
    IdentitiesOnly yes
EOF
    chmod 600 ~/.ssh/config
    check_result "SSH config created"
fi

section "4. KNOWN HOSTS CHECK"

if ssh-keygen -F 161.97.116.47 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Server is in known_hosts${NC}"
else
    echo -e "${YELLOW}⚠ Server not in known_hosts${NC}"
    echo "  Adding to known_hosts..."
    ssh-keyscan -H 161.97.116.47 >> ~/.ssh/known_hosts 2>/dev/null
    check_result "Server added to known_hosts"
fi

section "5. AUTHORIZED_KEYS REPAIR"

echo "Creating clean authorized_keys file..."
echo "Save this to /tmp/authorized_keys_clean:"
echo
echo "---BEGIN AUTHORIZED_KEYS---"
cat ~/.ssh/deploy_ai_stream.pub
echo "---END AUTHORIZED_KEYS---"
echo

# Save to temp file for easy copying
cat ~/.ssh/deploy_ai_stream.pub > /tmp/authorized_keys_clean
echo -e "${GREEN}✓ Clean file saved to /tmp/authorized_keys_clean${NC}"

section "6. CONNECTION TEST"

echo "Testing SSH connection..."
echo "Command: ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ai-stream-server 'echo SUCCESS'"
echo

if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ai-stream-server 'echo SUCCESS' 2>/dev/null; then
    echo -e "${GREEN}✓ SSH CONNECTION SUCCESSFUL!${NC}"
else
    echo -e "${RED}✗ Connection failed${NC}"
    echo
    echo -e "${YELLOW}MANUAL FIX REQUIRED:${NC}"
    echo "1. Access server via Contabo console/VNC"
    echo "2. Login as root"
    echo "3. Run these commands:"
    echo
    echo "   # Backup existing file"
    echo "   mv ~/.ssh/authorized_keys ~/.ssh/authorized_keys.backup"
    echo
    echo "   # Create new authorized_keys"
    echo "   cat > ~/.ssh/authorized_keys << 'EOF'"
    cat ~/.ssh/deploy_ai_stream.pub
    echo "EOF"
    echo
    echo "   # Fix permissions"
    echo "   chmod 700 ~/.ssh"
    echo "   chmod 600 ~/.ssh/authorized_keys"
    echo
    echo "   # Verify"
    echo "   ssh-keygen -l -f ~/.ssh/authorized_keys"
    echo
    echo "4. Then test from your local machine:"
    echo "   ssh ai-stream-server 'echo Connected!'"
fi

section "7. DEBUGGING INFO"

echo "If connection still fails, run this for detailed debug:"
echo "  ssh -vvv ai-stream-server"
echo
echo "Check server logs with:"
echo "  tail -f /var/log/auth.log  # On server"
echo
echo "Your public key fingerprint is:"
ssh-keygen -l -f ~/.ssh/deploy_ai_stream.pub
