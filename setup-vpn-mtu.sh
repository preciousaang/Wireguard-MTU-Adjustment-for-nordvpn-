#!/bin/bash

# ==============================================================================
# Script Name: setup-vpn-mtu.sh
# Description: Automates persistent MTU scaling for NordVPN (NordLynx/WireGuard)
#              to resolve packet fragmentation/race condition issues.
# Usage:       sudo ./setup-vpn-mtu.sh [optional_mtu_value]
# ==============================================================================

# Ensure the script is run with root/sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This script must be run as root. Please use: sudo $0"
    exit 1
fi

# Set the target MTU (use first argument if provided, otherwise default to 1400)
TARGET_MTU=${1:-1400}
SCRIPT_PATH="/usr/local/bin/fix-nord-mtu.sh"
UDEV_RULE_PATH="/etc/udev/rules.d/99-nordlynx-mtu.rules"

echo "🚀 Starting NordLynx MTU automation setup..."
echo "⚙️  Target MTU size set to: $TARGET_MTU"

# ------------------------------------------------------------------------------
# Step 1: Create the delayed background execution script
# ------------------------------------------------------------------------------
echo "📝 Creating background helper script at $SCRIPT_PATH..."

cat << EOF > "$SCRIPT_PATH"
#!/bin/bash
# Generated automatically by setup-vpn-mtu.sh
# Wait 2 seconds for NordVPN daemon to finish its initial handshake overrides
sleep 2
# Force the system interface to scale to the optimized MTU size
/usr/bin/ip link set dev nordlynx mtu $TARGET_MTU
EOF

# Make the helper script executable
chmod +x "$SCRIPT_PATH"
echo "✅ Helper script created and permissions set to executable."

# ------------------------------------------------------------------------------
# Step 2: Create the Kernel Udev rule to trigger on interface creation
# ------------------------------------------------------------------------------
echo "📝 Writing kernel Udev rule to $UDEV_RULE_PATH..."

cat << EOF > "$UDEV_RULE_PATH"
# Generated automatically by setup-vpn-mtu.sh
# Launches the background MTU script when the nordlynx network adapter is added
SUBSYSTEM=="net", KERNEL=="nordlynx", ACTION=="add", RUN+="/bin/bash -c '$SCRIPT_PATH &'"
EOF

echo "✅ Udev rule written successfully."

# ------------------------------------------------------------------------------
# Step 3: Force the system to reload network management rules
# ------------------------------------------------------------------------------
echo "🔄 Reloading Linux Udev kernel rules..."
udevadm control --reload-rules && udevadm trigger

echo "=============================================================================="
echo "🎉 Setup complete! NordVPN MTU is now permanently optimized at $TARGET_MTU."
echo "💡 To test: Run 'nordvpn disconnect' then 'nordvpn connect'."
echo "=============================================================================="
