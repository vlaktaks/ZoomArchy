#!/bin/bash
# ZoomArchy Omarchy overlay plugin installation script
# This script is called by 'omarchy plugins install zoomarchy'

set -e

SCRIPT_DIR="$(dirname "$0")"
PLUGIN_ID="jp.zoomarchy"
CONFIG_DIR="$HOME/.config/omarchy/apps"
APP_CONFIG="$CONFIG_DIR/zoomarchy.env"

echo "Installing ZoomArchy overlay plugin..."

# Create user config directory if needed
mkdir -p "$CONFIG_DIR"

# Create config file with default values if it doesn't exist
if [ ! -f "$APP_CONFIG" ]; then
    cat > "$APP_CONFIG" << 'ENV_EOF'
# Zoom magnification level (range: 5-20)
ZOOM_LEVEL=10.0

# Highlight overlay color
HIGHLIGHT_COLOR=#38a169

# Minimum cursor distance before zoom activates (in pixels)
MIN_ZOOM_DISTANCE=100
ENV_EOF
fi

echo "Config created at: $APP_CONFIG"

echo "Installation complete."
echo ""
echo "To enable the plugin, run:"
echo "  omarchy plugins enable zoomarchy"
echo ""
echo "Configuration:"
cat "$APP_CONFIG"
