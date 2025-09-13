#!/bin/bash

# SSH Authentication Fix Script
# This script will help diagnose and fix the SSH authentication issue

set -e

echo "=== SSH Authentication Fix Script ==="
echo

# Step 1: Display local public key information
echo "1. Local public key details:"
echo "----------------------------"
if [ -f ~/.ssh/deploy_ai_stream.pub ]; then
    echo "Public key fingerprint:"
    ssh-keygen -l -f ~/.ssh/deploy_ai_stream.pub
    echo
    echo "Public key content:"
    cat ~/.ssh/deploy_ai_stream.pub
    echo
else
    echo "ERROR: Public key not found at ~/.ssh/deploy_ai_stream.pub"
    exit 1
fi

# Step 2: Create a properly formatted authorized_keys entry
echo "2. Creating properly formatted authorized_keys entry:"
echo "------------------------------------------------------"
echo "Saving to: authorized_keys_fixed.txt"
cat ~/.ssh/deploy_ai_stream.pub > /tmp/authorized_keys_fixed.txt
echo "File created with proper formatting"
echo

# Step 3: Generate SSH commands to fix the server
echo "3. Commands to fix the server's authorized_keys:"
echo "-------------------------------------------------"
echo "Option A: Direct fix (if you can SSH as user):"
echo "ssh ai-stream-server 'cat > ~/.ssh/authorized_keys' < ~/.ssh/deploy_ai_stream.pub"
echo

echo "Option B: Manual fix via console/VNC:"
echo "1. Login to server via Contabo console"
echo "2. Run: nano ~/.ssh/authorized_keys"
echo "3. Delete all content"
echo "4. Paste your public key (shown above)"
echo "5. Save and exit"
echo

# Step 4: Test the connection
echo "4. Test commands after fixing:"
echo "-------------------------------"
echo "ssh -v ai-stream-server 'echo Connection successful'"
echo

echo "5. Verify the fix on server:"
echo "-----------------------------"
echo "Once connected, run these commands on the server:"
echo "  chmod 700 ~/.ssh"
echo "  chmod 600 ~/.ssh/authorized_keys"
echo "  ssh-keygen -l -f ~/.ssh/authorized_keys  # Should show fingerprint"
echo "  cat ~/.ssh/authorized_keys  # Should show clean key format"
