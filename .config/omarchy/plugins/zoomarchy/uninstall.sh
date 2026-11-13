#!/bin/bash
# ZoomArchy Omarchy overlay plugin uninstallation script
# This script is called by 'omarchy plugins remove zoomarchy'

set -e

SCRIPT_DIR="$(dirname "$0")"
CONFIG_DIR="/usr/local/share/omarchy/apps"
APP_CONFIG="$CONFIG_DIR/zoomarchy.env"

echo "Removing ZoomArchy overlay plugin..."

# Remove config file if it exists
if [ -f "$APP_CONFIG" ]; then
    rm -f "$APP_CONFIG"
    echo "Config removed from: $APP_CONFIG"
fi

echo "Removal complete."
echo ""
echo "To reinstall, use:"
echo "  omarchy plugins install zoomarchy --enable"
