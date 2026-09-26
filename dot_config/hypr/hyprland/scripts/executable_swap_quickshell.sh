#!/usr/bin/env bash
# Swap between the Dynamite V3 setup and the Original Quickshell setup

set -euo pipefail

ACTIVE_LINK="$HOME/.config/quickshell-active"
DYNAMITE_DIR="$HOME/.config/quickshell.bak"
ORIGINAL_DIR="$HOME/.config/quickshell.original"

# Ensure both directories exist
if [ ! -d "$DYNAMITE_DIR" ] || [ ! -d "$ORIGINAL_DIR" ]; then
    notify-send -u critical "Quickshell Swap Error" "One of the config directories is missing."
    exit 1
fi

# Resolve current target
CURRENT=""
if [ -L "$ACTIVE_LINK" ]; then
    CURRENT="$(readlink -f "$ACTIVE_LINK" 2>/dev/null || true)"
elif [ -d "$ACTIVE_LINK" ]; then
    CURRENT="$(cd "$ACTIVE_LINK" && pwd -P)"
fi

if [ "$CURRENT" = "$ORIGINAL_DIR" ]; then
    TARGET="$DYNAMITE_DIR"
else
    TARGET="$ORIGINAL_DIR"
fi

# Atomically update quickshell-active symlink
ln -sfn "$TARGET" "$ACTIVE_LINK"

# Update wlogout symlink if layout exists in target
if [ -f "$TARGET/wlogout/layout" ]; then
    rm -rf "$HOME/.config/wlogout" 2>/dev/null || true
    ln -sf "$TARGET/wlogout" "$HOME/.config/wlogout" 2>/dev/null || true
fi

# Sync environment
export qsDir="$ACTIVE_LINK"
dbus-update-activation-environment --systemd qsDir 2>/dev/null || true
systemctl --user import-environment qsDir 2>/dev/null || true

# Terminate existing quickshell
pkill -x qs 2>/dev/null || true
for i in {1..20}; do
    pgrep -x qs >/dev/null || break
    sleep 0.05
done
pkill -9 -x qs 2>/dev/null || true

# Launch the active configuration detached
qs -p "$ACTIVE_LINK" -d

# Notify user
notify-send -a "Quickshell" -i preferences-desktop-theme "Quickshell Swapped" -t 2000 2>/dev/null || true
