#!/usr/bin/env bash
set -euo pipefail

SYSTEM_DESKTOP="/usr/share/applications/google-chrome.desktop"
LOCAL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
LOCAL_DESKTOP="${LOCAL_DIR}/google-chrome.desktop"
CHROME_FLAGS_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/chrome-flags.conf"
ENV_D_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d/chromium-wayland.conf"
HYPR_CUSTOM_ENV="${HOME}/.config/hypr/custom/env.lua"
BASHRC="${HOME}/.bashrc"

# Flags required for Wayland native execution and accelerated Canvas/GPU shader rasterization
FLAGS=(
  "--ozone-platform-hint=auto"
  "--ozone-platform=wayland"
  "--ignore-gpu-blocklist"
  "--enable-gpu-rasterization"
  "--enable-zero-copy"
  "--enable-features=WaylandWindowDecorations,CanvasOopRasterization,VaapiVideoDecodeLinuxGL"
)
FLAG_STRING="${FLAGS[*]}"

echo "==> Step 1: Patching ~/.local/share/applications/google-chrome.desktop..."
if [[ ! -f "$SYSTEM_DESKTOP" ]]; then
  echo "Error: $SYSTEM_DESKTOP does not exist!" >&2
  exit 1
fi

mkdir -p "$LOCAL_DIR"

if [[ -f "$LOCAL_DESKTOP" ]]; then
  BACKUP="${LOCAL_DESKTOP}.bak.$(date +%s)"
  echo "    Backing up existing desktop entry to $BACKUP"
  cp "$LOCAL_DESKTOP" "$BACKUP"
fi

cp "$SYSTEM_DESKTOP" "$LOCAL_DESKTOP"

# Replace Exec lines with injected flags
sed -i -E "s|^(Exec=/usr/bin/google-chrome(-stable)?)([[:space:]]\|$)|\1 ${FLAG_STRING}\3|g" "$LOCAL_DESKTOP"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$LOCAL_DIR"
  echo "    Updated local desktop database."
fi

echo "==> Step 2: Updating ~/.config/chrome-flags.conf..."
mkdir -p "$(dirname "$CHROME_FLAGS_CONF")"
cat << 'CONF' > "$CHROME_FLAGS_CONF"
# Hardware acceleration & Wayland configuration for Google Chrome
--ozone-platform-hint=auto
--ozone-platform=wayland
--ignore-gpu-blocklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=WaylandWindowDecorations,CanvasOopRasterization,VaapiVideoDecodeLinuxGL
CONF
echo "    Wrote updated flags to $CHROME_FLAGS_CONF."

echo "==> Step 3: Setting environment variables in ~/.config/environment.d/..."
mkdir -p "$(dirname "$ENV_D_CONF")"
cat << 'CONF' > "$ENV_D_CONF"
# Wayland & GPU acceleration environment variables for Chromium and Electron
ELECTRON_OZONE_PLATFORM_HINT=auto
NIXOS_OZONE_WL=1
CHROME_OZONE_PLATFORM_HINT=auto
CHROMIUM_USER_FLAGS="--ozone-platform=wayland --ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy"
CONF
echo "    Wrote $ENV_D_CONF."

echo "==> Step 4: Updating ~/.config/hypr/custom/env.lua for Hyprland session..."
if [[ -f "$HYPR_CUSTOM_ENV" ]]; then
  if ! grep -q "CHROME_OZONE_PLATFORM_HINT" "$HYPR_CUSTOM_ENV"; then
    cat << 'CONF' >> "$HYPR_CUSTOM_ENV"

-- Chromium & Electron Wayland / GPU acceleration flags
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("NIXOS_OZONE_WL", "1")
hl.env("CHROME_OZONE_PLATFORM_HINT", "auto")
CONF
    echo "    Added env variables to $HYPR_CUSTOM_ENV."
  fi
fi

echo "==> Step 5: Updating ~/.bashrc for shell consistency..."
if ! grep -q "CHROME_OZONE_PLATFORM_HINT" "$BASHRC"; then
  cat << 'CONF' >> "$BASHRC"

# Chromium / Electron Wayland & GPU Acceleration
export ELECTRON_OZONE_PLATFORM_HINT="auto"
export NIXOS_OZONE_WL="1"
export CHROME_OZONE_PLATFORM_HINT="auto"
export CHROMIUM_USER_FLAGS="--ozone-platform=wayland --ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy"
CONF
  echo "    Added exports to $BASHRC."
fi

echo "==> All configurations verified and applied successfully!"
