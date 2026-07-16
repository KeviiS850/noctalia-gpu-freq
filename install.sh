#!/usr/bin/env bash
# gpu-freq installer for Noctalia/QuickShell
# Usage: curl -fsSL https://raw.githubusercontent.com/keviis850/noctalia-gpu-freq/main/install.sh | bash

set -euo pipefail

REPO="keviis850/noctalia-gpu-freq"
BRANCH="main"
PLUGIN_DIR="${HOME}/.config/noctalia/plugins/gpu-freq"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo "🔧 Installing gpu-freq plugin for Noctalia..."

# Clone plugin files
git clone --depth 1 --branch "${BRANCH}" "https://github.com/${REPO}.git" "${TMP_DIR}/repo" 2>/dev/null || {
    echo "❌ Failed to clone repository. Check internet connection or repo visibility."
    exit 1
}

# Create plugin directory
mkdir -p "${PLUGIN_DIR}"

# Copy plugin files
cp -r "${TMP_DIR}/repo/"* "${PLUGIN_DIR}/"

# Remove git and install script from target
rm -rf "${PLUGIN_DIR}/.git" "${PLUGIN_DIR}/install.sh" 2>/dev/null || true

echo "✅ Plugin installed to ${PLUGIN_DIR}"
echo ""
echo "📋 Next steps:"
echo "  1. Restart Noctalia (or reload QuickShell)"
echo "  2. Open Noctalia Settings → Plugins → Enable 'GPU Freq'"
echo "  3. Add widget to bar: Right-click bar → Add Widget → GPU Freq"
echo "  4. Left-click panel to open full GPU monitor"
echo ""
echo "🔐 If widget shows '? MHz', run the udev setup:"
echo "   sudo tee /etc/udev/rules.d/99-intel-gpu-perms.rules <<'EOF'"
echo "   SUBSYSTEM==\"drm\", KERNEL==\"card*\", RUN+=\"/bin/chmod 644 /sys/class/drm/%k/gt_*_freq_mhz\""
echo "   EOF"
echo "   sudo udevadm control --reload-rules && sudo udevadm trigger"
echo ""
echo "📖 Full docs: https://github.com/${REPO}#readme"