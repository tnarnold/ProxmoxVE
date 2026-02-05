#!/usr/bin/env bash

# Configuration
PROXMOX_HOST="${PROXMOX_HOST:-root@192.168.1.50}" # Default or from env env
REMOTE_DIR="/tmp/test-openclaw-$(date +%s)"
CT_SCRIPT="ct/openclaw.sh"
INSTALL_SCRIPT="install/openclaw-install.sh"
BUILD_FUNC="misc/build.func"

# Check if files exist exists locally
if [[ ! -f "$CT_SCRIPT" ]] || [[ ! -f "$INSTALL_SCRIPT" ]]; then
    echo "Error: Run this script from the root of the repo."
    exit 1
fi

echo "🚀 Deploying to $PROXMOX_HOST..."

# 1. Create remote directory
ssh "$PROXMOX_HOST" "mkdir -p $REMOTE_DIR/ct $REMOTE_DIR/install $REMOTE_DIR/misc"

# 2. Copy files (including build.func if we want to patch it)
# We MUST copy build.func because we need to patch the install script downloader
scp "$CT_SCRIPT" "$PROXMOX_HOST:$REMOTE_DIR/$CT_SCRIPT"
scp "$INSTALL_SCRIPT" "$PROXMOX_HOST:$REMOTE_DIR/$INSTALL_SCRIPT"
scp "$BUILD_FUNC" "$PROXMOX_HOST:$REMOTE_DIR/$BUILD_FUNC"

# 3. Patch build.func on the remote server
# We are replacing the curl command that downloads the install script from GitHub
# with a command that pushes our local (already SCP'd) file into the container.
# Warning: This relies on the exact structure of build.func.
echo "🔧 Patching remote build.func..."
ssh "$PROXMOX_HOST" "sed -i 's|lxc-attach -n \"\$CTID\" -- bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/install/\${var_install}.sh)\"|pct push \"\$CTID\" $REMOTE_DIR/install/\${var_install}.sh /tmp/\${var_install}.sh; lxc-attach -n \"\$CTID\" -- bash /tmp/\${var_install}.sh|' $REMOTE_DIR/$BUILD_FUNC"

# 4. Patch ct/openclaw.sh to use the LOCAL patched build.func
echo "🔧 Patching remote ct script..."
# Replace the source line that downloads tools.func/build.func from GitHub
# with sourcing our local patched file
# Original: source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# We can't easily match the whole line, so let's match the URL
ssh "$PROXMOX_HOST" "sed -i 's|source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)|source $REMOTE_DIR/misc/build.func|' $REMOTE_DIR/$CT_SCRIPT"

# 5. Run the script
echo "▶️  Running test on Proxmox..."
ssh -t "$PROXMOX_HOST" "bash $REMOTE_DIR/$CT_SCRIPT"

echo "✅ Test script finished (check output above)"
