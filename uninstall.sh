#!/bin/bash
# ZoomArchy Uninstall Script
# Run with: bash uninstall.sh

set -e

echo "Uninstalling ZoomArchy..."

PLUGIN_ID="jp.zoomarchy"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
CONFIG_DIR="$HOME/.config/omarchy/apps"
APP_CONFIG="$CONFIG_DIR/zoomarchy.env"

# Disable the plugin
echo "Disabling plugin..."
omarchy plugin disable "$PLUGIN_ID" 2>&1 || echo "Plugin may already be disabled."

# Remove plugin files
if [ -d "$PLUGIN_DIR" ]; then
    echo "Removing plugin directory: $PLUGIN_DIR"
    rm -rf "$PLUGIN_DIR"
    echo "Plugin files removed."
else
    echo "Plugin directory not found: $PLUGIN_DIR"
fi

# Remove config file (only if it belongs to ZoomArchy)
if [ -f "$APP_CONFIG" ]; then
    echo "Removing config file: $APP_CONFIG"
    rm -f "$APP_CONFIG"
    echo "Config file removed."
fi

# Remove shortcut entry
SHORTCUTS_FILE="$HOME/.config/omarchy/default/omarchy/shortcuts"
if [ -f "$SHORTCUTS_FILE" ]; then
    if grep -q "panel $PLUGIN_ID" "$SHORTCUTS_FILE"; then
        sed -i "/panel $PLUGIN_ID/d" "$SHORTCUTS_FILE"
        echo "Removed shortcut entry from $SHORTCUTS_FILE"
    fi
fi

echo ""
echo "✓ ZoomArchy uninstalled successfully"