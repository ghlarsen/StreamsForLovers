#!/usr/bin/env python3
"""
SSH Authorized Keys Repair Tool
Fixes common formatting issues in authorized_keys files
"""

import os
import sys
import subprocess
import re
from pathlib import Path

class SSHKeyRepair:
    def __init__(self):
        self.home = Path.home()
        self.ssh_dir = self.home / '.ssh'
        self.private_key = self.ssh_dir / 'deploy_ai_stream'
        self.public_key = self.ssh_dir / 'deploy_ai_stream.pub'
        
    def validate_public_key(self):
        """Validate the local public key format"""
        if not self.public_key.exists():
            print(f"❌ Public key not found: {self.public_key}")
            return False
            
        with open(self.public_key, 'r') as f:
            key_content = f.read().strip()
            
        # Check for valid SSH key format
        valid_formats = ['ssh-rsa', 'ssh-ed25519', 'ssh-dss', 'ecdsa-sha2']
        if not any(key_content.startswith(fmt) for fmt in valid_formats):
            print(f"❌ Invalid key format. Key should start with one of: {valid_formats}")
            return False
            
        # Check key structure (should be: type key comment)
        parts = key_content.split()
        if len(parts) < 2:
            print("❌ Invalid key structure. Expected: [type] [key] [optional comment]")
            return False
            
        print(f"✅ Public key format valid: {parts[0]}")
        return True
        
    def get_key_fingerprint(self):
        """Get the fingerprint of the public key"""
        try:
            result = subprocess.run(
                ['ssh-keygen', '-l', '-f', str(self.public_key)],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                fingerprint = result.stdout.strip().split()[1]
                print(f"🔑 Key fingerprint: {fingerprint}")
                return fingerprint
            else:
                print(f"❌ Could not get fingerprint: {result.stderr}")
                return None
        except Exception as e:
            print(f"❌ Error getting fingerprint: {e}")
            return None
            
    def create_clean_authorized_keys(self):
        """Create a properly formatted authorized_keys file"""
        if not self.public_key.exists():
            print("❌ Cannot create authorized_keys - public key not found")
            return None
            
        with open(self.public_key, 'r') as f:
            key_content = f.read().strip()
            
        # Ensure single line, no extra whitespace
        key_content = ' '.join(key_content.split())
        
        # Ensure it ends with a newline
        key_content += '\n'
        
        # Save to temp file
        output_file = Path('/tmp/authorized_keys_fixed')
        with open(output_file, 'w') as f:
            f.write(key_content)
            
        # Set proper permissions
        os.chmod(output_file, 0o600)
        
        print(f"✅ Clean authorized_keys created: {output_file}")
        print(f"   Size: {len(key_content)} bytes")
        print(f"   Content: {key_content[:50]}...")
        
        return output_file
        
    def generate_fix_commands(self):
        """Generate commands to fix the server"""
        with open(self.public_key, 'r') as f:
            key_content = f.read().strip()
            
        print("\n" + "="*60)
        print("FIX COMMANDS FOR SERVER")
        print("="*60)
        
        print("\n1. QUICK FIX (via console/VNC):")
        print("-" * 40)
        print("# Login to server console and run:")
        print("cat > ~/.ssh/authorized_keys << 'KEYEND'")
        print(key_content)
        print("KEYEND")
        print("chmod 600 ~/.ssh/authorized_keys")
        print("chmod 700 ~/.ssh")
        
        print("\n2. ALTERNATIVE FIX (if you can somehow SSH):")
        print("-" * 40)
        print("# From your local machine:")
        print(f"cat {self.public_key} | ssh root@161.97.116.47 'cat > ~/.ssh/authorized_keys'")
        
        print("\n3. VERIFY THE FIX:")
        print("-" * 40)
        print("# On the server, run:")
        print("ssh-keygen -l -f ~/.ssh/authorized_keys")
        print("# Should show your fingerprint")
        
        print("\n4. TEST CONNECTION:")
        print("-" * 40)
        print("# From your local machine:")
        print("ssh -v ai-stream-server 'echo SUCCESS'")
        
    def diagnose_connection(self):
        """Run SSH connection diagnosis"""
        print("\n" + "="*60)
        print("CONNECTION DIAGNOSIS")
        print("="*60)
        
        print("\nTrying to connect with verbose output...")
        print("Command: ssh -vv -o ConnectTimeout=5 ai-stream-server 'echo TEST' 2>&1")
        
        try:
            result = subprocess.run(
                ['ssh', '-vv', '-o', 'ConnectTimeout=5', 'ai-stream-server', 'echo TEST'],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            # Parse debug output for key information
            output = result.stderr
            
            if "Offering public key" in output:
                print("✅ Key is being offered to server")
            else:
                print("❌ Key not being offered")
                
            if "Server accepts key" in output:
                print("✅ Server accepts the key algorithm")
            elif "send_pubkey_test: no mutual signature algorithm" in output:
                print("❌ Server rejects key algorithm")
                
            if "Permission denied (publickey" in output:
                print("❌ Server rejected the key - authorized_keys issue")
                
            if "Connection refused" in output:
                print("❌ Cannot connect to server - network or firewall issue")
                
            if result.returncode == 0:
                print("✅ CONNECTION SUCCESSFUL!")
            else:
                print("❌ Connection failed")
                
        except subprocess.TimeoutExpired:
            print("❌ Connection timeout - server not responding")
        except Exception as e:
            print(f"❌ Error during diagnosis: {e}")

def main():
    print("SSH Authorized Keys Repair Tool")
    print("=" * 60)
    
    repair = SSHKeyRepair()
    
    # Step 1: Validate local key
    print("\n📋 STEP 1: Validating local public key")
    if not repair.validate_public_key():
        sys.exit(1)
        
    # Step 2: Get fingerprint
    print("\n📋 STEP 2: Getting key fingerprint")
    fingerprint = repair.get_key_fingerprint()
    
    # Step 3: Create clean authorized_keys
    print("\n📋 STEP 3: Creating clean authorized_keys file")
    clean_file = repair.create_clean_authorized_keys()
    
    # Step 4: Generate fix commands
    print("\n📋 STEP 4: Generating server fix commands")
    repair.generate_fix_commands()
    
    # Step 5: Diagnose connection
    print("\n📋 STEP 5: Diagnosing current connection")
    repair.diagnose_connection()
    
    print("\n" + "="*60)
    print("SUMMARY")
    print("="*60)
    print("""
The server's authorized_keys file appears to be corrupted.
This is why ssh-keygen -l -f ~/.ssh/authorized_keys fails on the server.

TO FIX:
1. Access the server via Contabo's web console/VNC (not SSH)
2. Copy and run the commands shown above in section "QUICK FIX"
3. The commands will replace the corrupted authorized_keys with your clean key
4. After fixing, test with: ssh ai-stream-server 'echo SUCCESS'

The issue is NOT with your local setup - everything is configured correctly.
The problem is the authorized_keys file on the server is malformed.
""")

if __name__ == "__main__":
    main()
