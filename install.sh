#!/bin/bash
# ZoomArchy install script for Omarchy (Quickshell overlay plugin)
# Run with: bash install.sh

set -e

echo "Installing ZoomArchy as Omarchy overlay plugin..."

PLUGIN_ID="jp.zoomarchy"
PLUGIN_SRC_DIR="$(dirname "$0")/.config/omarchy/plugins/zoomarchy"
PLUGIN_DEST_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

# Check dependencies
echo "Checking dependencies..."
MISSING_DEPS=()

if ! command -v grim &> /dev/null; then
    MISSING_DEPS+=("grim (Wayland screenshot tool)")
fi

if ! command -v omarchy &> /dev/null; then
    MISSING_DEPS+=("omarchy (Omarchy CLI)")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "Error: Missing required dependencies:"
    for dep in "${MISSING_DEPS[@]}"; do
        echo "  - $dep"
    done
    echo ""
    echo "Please install missing dependencies before proceeding."
    exit 1
fi

echo "All dependencies present."

# Copy plugin files
echo "Copying plugin files..."
mkdir -p "$PLUGIN_DEST_DIR"
cp -r "$PLUGIN_SRC_DIR"/. "$PLUGIN_DEST_DIR/"
echo "Plugin files copied to: $PLUGIN_DEST_DIR"

# Validate the plugin
echo "Validating plugin..."
if omarchy plugin validate "$PLUGIN_DEST_DIR" 2>&1; then
    echo "Plugin validation passed."
else
    echo "Warning: Plugin validation reported issues. Review the output above."
fi

# Enable the plugin
echo "Enabling plugin..."
omarchy plugin enable "$PLUGIN_ID" 2>&1 || echo "Plugin may already be enabled."

# Register panel in Omarchy shell shortcuts list (idempotent, if file exists)
SHORTCUTS_FILE="$HOME/.config/omarchy/default/omarchy/shortcuts"
if [ -f "$SHORTCUTS_FILE" ]; then
    if ! grep -qx "panel $PLUGIN_ID" "$SHORTCUTS_FILE" 2>/dev/null; then
        echo "panel $PLUGIN_ID" >> "$SHORTCUTS_FILE"
        echo "Added panel entry to: $SHORTCUTS_FILE"
    else
        echo "Panel entry already present in: $SHORTCUTS_FILE"
    fi
else
    echo "Note: Omarchy shortcuts file not found at $SHORTCUTS_FILE (skipping panel registration)."
fi

# Check for existing Hyprland keybinding without modifying user config
BINDING_FOUND=false
for cfg in "$HOME/.config/hypr/bindings.lua" "$HOME/.config/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.lua"; do
    if [ -f "$cfg" ] && grep -q "$PLUGIN_ID" "$cfg" 2>/dev/null; then
        BINDING_FOUND=true
        break
    fi
done
if [ "$BINDING_FOUND" = false ] && [ -d "$HOME/.config/hypr" ]; then
    if grep -Rqs "$PLUGIN_ID" "$HOME/.config/hypr" 2>/dev/null; then
        BINDING_FOUND=true
    fi
fi

echo ""
echo "✓ ZoomArchy plugin installed/enabled"
echo "✓ Plugin ID: $PLUGIN_ID"
echo "✓ Plugin directory: $PLUGIN_DEST_DIR"

if [ "$BINDING_FOUND" = true ]; then
    echo "✓ Existing Hyprland binding referencing $PLUGIN_ID detected (not modified)."
    echo "  Use your configured shortcut (e.g. Super+Z) or reload Hyprland if needed."
else
    echo "⚠ No Hyprland keybinding for $PLUGIN_ID was detected."
    echo "  To bind Super+Z, add this to your Hyprland/Omarchy bindings configuration"
    echo "  (only if not already present, in the correct file for your setup):"
    echo '    o.bind("SUPER + Z", "ZoomArchy zoom", { panel = "jp.zoomarchy" })'
    echo "  Hyprland configuration layouts vary; do not duplicate existing bindings."
fi

echo "  You can also summon directly: omarchy-shell shell summon $PLUGIN_ID '{}'"
echo "✓ To uninstall: bash uninstall.sh"
