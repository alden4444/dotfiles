#!/usr/bin/env bash
# Record the last-used wallpaper for a theme, in ~/.config/quickshell/wallpaper-state
# (one "theme<TAB>path" line per theme). Usage: wallpaper-record.sh <theme> <path>
set -uo pipefail
t="${1:?theme}"; p="${2:?path}"
# Determine active quickshell directory from environment, variables.lua, or symlink
if [ -z "${qsDir:-}" ]; then
    if [ -f "$HOME/.config/hypr/hyprland/variables.lua" ] && command -v lua >/dev/null 2>&1; then
        qsDir=$(lua -e 'HOME=os.getenv("HOME"); hl={env=function()end}; dofile(HOME.."/.config/hypr/hyprland/variables.lua"); print(qsDir)' 2>/dev/null)
    fi
fi
if [ -z "${qsDir:-}" ] && [ -L "$HOME/.config/quickshell-active" ]; then
    qsDir="$(readlink -f "$HOME/.config/quickshell-active")"
fi
if [ -z "${qsDir:-}" ]; then
    if [ -f "$HOME/.config/quickshell/shell.qml" ]; then
        qsDir="$HOME/.config/quickshell"
    else
        qsDir="$HOME/.config/quickshell.bak"
    fi
fi
state="${qsDir}/wallpaper-state"
mkdir -p "$(dirname "$state")"
tmp="$(mktemp)"
[ -f "$state" ] && grep -vP "^${t}\t" "$state" >"$tmp" 2>/dev/null || true
printf '%s\t%s\n' "$t" "$p" >>"$tmp"
mv "$tmp" "$state"
