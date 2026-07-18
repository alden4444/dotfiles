#!/usr/bin/env bash
# Apply a curated wallust colorscheme by name (or path) and reload every app.
#
# wallust `cs` writes templates but does NOT run [hooks] (only `run` does), so the
# reloads are performed here. Quickshell needs no reload, Theme.qml reads
# colors.json via a watched FileView and restyles live.
#
# GTK is OPTION B: the hand-made custom GTK 3/4 themes are preserved and switched
# from ~/.config/colorschemes/<name>/ (symlink the per-theme gtk-4.0 + set the GTK
# theme name), GTK is NOT recolored by wallust templates.
#
# Usage: theme-apply.sh <name|/path/to/scheme.json>
#   names resolve to ~/.config/wallust/colorschemes/<name>.json

set -uo pipefail
arg="${1:?usage: theme-apply.sh <name|scheme.json>}"

scheme="$arg"
[ -f "$scheme" ] || scheme="$HOME/.config/wallust/colorschemes/${arg}.json"
if [ ! -f "$scheme" ]; then
    notify-send "Theme" "No colorscheme: $arg" -u critical 2>/dev/null || true
    echo "no colorscheme: $arg" >&2
    exit 1
fi
name="$(basename "$scheme" .json)"

cd "$HOME/.config"

wallust cs "$scheme" -s || { echo "wallust cs failed" >&2; exit 1; }

# --- sync the shell's Config (theme) + auto-apply this theme's last-used wallpaper ---
# Keeps config.json in sync regardless of entry point (CLI or in-shell switcher),
# and restores the wallpaper last chosen for this theme (else its first one).
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
cfg="${qsDir}/config.json"
state="${qsDir}/wallpaper-state"
wpdir="$HOME/.config/colorschemes/$name/wallpapers"
wp=""
[ -f "$state" ] && wp="$(awk -F'\t' -v t="$name" '$1==t{print $2; exit}' "$state")"
if [ -z "$wp" ] || [ ! -f "$wp" ]; then
    wp="$(find "$wpdir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | head -1)"
fi
if command -v jq >/dev/null 2>&1 && [ -f "$cfg" ]; then
    tmp="$(mktemp)"
    if [ -n "$wp" ] && [ -f "$wp" ]; then
        jq --arg t "$name" --arg w "$wp" '.theme=$t | .wallpaper=$w' "$cfg" >"$tmp" && mv "$tmp" "$cfg" || rm -f "$tmp"
        "$HOME/.config/wallust/wallpaper-record.sh" "$name" "$wp" 2>/dev/null || true
    else
        jq --arg t "$name" '.theme=$t' "$cfg" >"$tmp" && mv "$tmp" "$cfg" || rm -f "$tmp"
    fi
fi

# Check if any browser is running before reload
active_proc=""
for proc in "firefox-bin" "firefox" "firefox-nightly" "chrome" "google-chrome" "google-chrome-stable" "zen-browser" "zen" "brave" "chromium" "microsoft-edge-stable" "opera" "librewolf"; do
    if pgrep -x "$proc" >/dev/null; then
        active_proc="$proc"
        break
    fi
done

# Terminate the browser process immediately to avoid slow Wayland protocol crash during reload
if [ -n "$active_proc" ]; then
    pkill -x "$active_proc" || true
    # Wait for the browser process to fully exit (up to 1.5 seconds)
    timeout=30 # 30 * 0.05s = 1.5s
    while [ $timeout -gt 0 ]; do
        if ! pgrep -x "$active_proc" >/dev/null; then
            break
        fi
        sleep 0.05
        timeout=$((timeout - 1))
    done
    # Force kill if still running to guarantee it's closed instantly
    if pgrep -x "$active_proc" >/dev/null; then
        pkill -9 -x "$active_proc" || true
        # Wait up to 0.5s for OS to release it
        timeout=10
        while [ $timeout -gt 0 ] && pgrep -x "$active_proc" >/dev/null; do
            sleep 0.05
            timeout=$((timeout - 1))
        done
    fi
fi

# --- non-GTK reloads (cs skips wallust [hooks]) ---
hyprctl reload    >/dev/null 2>&1 || true

# Relaunch the browser immediately in the background so it starts opening in parallel with the rest of the script
if [ -n "$active_proc" ]; then
    if command -v lua >/dev/null 2>&1; then
        browser_cmd=$(lua -e 'HOME=os.getenv("HOME"); hl={env=function()end}; dofile(HOME.."/.config/hypr/hyprland/variables.lua"); if io.open(HOME.."/.config/hypr/custom/variables.lua") then dofile(HOME.."/.config/hypr/custom/variables.lua") end; print(browser)' 2>/dev/null)
        if [ -n "$browser_cmd" ]; then
            eval "${browser_cmd/#\~/$HOME} &"
        fi
    fi
fi

pkill -USR1 kitty 2>/dev/null      || true
# foot: new windows pick up colors. vesktop: hot-reloads CSS. quickshell: live FileView.

# --- GTK (option B): switch the matching custom GTK 3/4 theme, if one exists ---
csdir="$HOME/.config/colorschemes/$name"
if [ -d "$csdir/gtk-4.0" ]; then
    ln -sf  "$csdir/gtk-4.0/gtk.css"      "$HOME/.config/gtk-4.0/gtk.css"      2>/dev/null || true
    ln -sf  "$csdir/gtk-4.0/gtk-dark.css" "$HOME/.config/gtk-4.0/gtk-dark.css" 2>/dev/null || true
    [ -e "$csdir/gtk-4.0/assets" ] && ln -sfn "$csdir/gtk-4.0/assets" "$HOME/.config/gtk-4.0/assets" 2>/dev/null || true
fi
if [ -f "$csdir/gtk-theme" ]; then
    gsettings set org.gnome.desktop.interface gtk-theme "$(cat "$csdir/gtk-theme")" 2>/dev/null || true
fi

# --- spicetify (option B: curated Sleek color schemes; best-effort name match) ---
if command -v spicetify >/dev/null 2>&1; then
    sptheme="$(spicetify config current_theme 2>/dev/null)"
    ini="$HOME/.config/spicetify/Themes/${sptheme}/color.ini"
    for cand in "$name" "${name}-dark"; do
        if [ -f "$ini" ] && grep -q "^\[${cand}\]" "$ini"; then
            spicetify config color_scheme "$cand" >/dev/null 2>&1 || true
            spicetify refresh                     >/dev/null 2>&1 || true
            break
        fi
    done
fi

# --- nvim / NvChad (option B): patch the theme name in the live chadrc ---
nvchadrc="$HOME/.config/nvim/lua/chadrc.lua"
if [ -f "$csdir/nvim/lua/chadrc.lua" ] && [ -f "$nvchadrc" ]; then
    nvtheme="$(grep -oP 'theme\s*=\s*"\K[^"]+' "$csdir/nvim/lua/chadrc.lua" 2>/dev/null | head -1)"
    [ -n "$nvtheme" ] && sed -i "s/theme = \"[^\"]*\"/theme = \"$nvtheme\"/" "$nvchadrc" 2>/dev/null || true
fi

# --- vscodium (option B): set workbench.colorTheme to the named extension theme ---
for cfg in "$HOME/.config/VSCodium/User/settings.json" "$HOME/.config/Antigravity IDE/User/settings.json"; do
    if [ -f "$csdir/vscodium-theme" ] && [ -f "$cfg" ] && command -v jq >/dev/null 2>&1; then
        vsname="$(cat "$csdir/vscodium-theme")"
        tmp="$(mktemp)"
        if jq --arg t "$vsname" '.["workbench.colorTheme"]=$t' "$cfg" >"$tmp" 2>/dev/null; then
            mv "$tmp" "$cfg"
        else
            rm -f "$tmp"
        fi
    fi
done
if [ -f "$HOME/.config/VSCodium/update-theme.sh" ]; then
    "$HOME/.config/VSCodium/update-theme.sh" wallust
fi

# Relaunch complete

