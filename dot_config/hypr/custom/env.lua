-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples

-- Chromium & Electron Wayland / GPU acceleration flags
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("NIXOS_OZONE_WL", "1")
hl.env("CHROME_OZONE_PLATFORM_HINT", "auto")

-- Prioritize NVIDIA RTX 5070 (card1) over AMD iGPU (card2) for display & Wayland clients
hl.env("AQ_DRM_DEVICES", "/dev/dri/card1:/dev/dri/card2")
