#!/usr/bin/env bash
# gpu-freq installer for Noctalia / Quickshell
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/KeviiS850/noctalia-gpu-freq/main/install.sh | bash
#   # or as root for udev rule deployment:
#   sudo ./install.sh

set -euo pipefail

REPO="KeviiS850/noctalia-gpu-freq"
BRANCH="main"
PLUGIN_DIR="${HOME}/.config/noctalia/plugins/gpu-freq"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo "gpu-freq installer for Noctalia"

# Clone plugin files
git clone --depth 1 --branch "${BRANCH}" "https://github.com/${REPO}.git" "${TMP_DIR}/repo" 2>/dev/null || {
    echo "Failed to clone repository. Check internet connection or repo visibility."
    exit 1
}

# Create plugin directory
mkdir -p "${PLUGIN_DIR}"

# Copy plugin files
cp -r "${TMP_DIR}/repo/." "${PLUGIN_DIR}/"

# Strip git metadata and the install script from the target copy
rm -rf "${PLUGIN_DIR}/.git" "${PLUGIN_DIR}/.gitignore" "${PLUGIN_DIR}/.backups" "${PLUGIN_DIR}/install.sh" 2>/dev/null || true

echo "Plugin installed to ${PLUGIN_DIR}"
echo

# Install udev rule if running as root (e.g., sudo ./install.sh)
if [ "$(id -u)" -eq 0 ]; then
    echo "Installing udev rule for GPU permissions..."
    install -m 644 "${TMP_DIR}/repo/99-intel-gpu-perms.rules" /etc/udev/rules.d/
    udevadm control --reload-rules
    udevadm trigger
    echo "udev rule installed and reloaded"
else
    echo "To enable GPU permissions, run:"
    echo "  sudo cp ${PLUGIN_DIR}/99-intel-gpu-perms.rules /etc/udev/rules.d/"
    echo "  sudo udevadm control --reload-rules && sudo udevadm trigger"
fi

cat <<EOF

Next steps:
  1. Restart Noctalia: \`pkill -9 quickshell && ~/.config/niri/scripts/launch-noctalia.sh &\`
  2. Open Noctalia Settings -> Plugins -> Enable 'GPU Frequency'
  3. Right-click bar -> Add Widget -> GPU Frequency
  4. Right-click widget -> Settings -> toggle display options
  5. Hover the widget for tooltip with all frequencies

Docs: https://github.com/${REPO}#readme
EOF
