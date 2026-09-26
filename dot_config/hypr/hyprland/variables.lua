qsDir = HOME .. "/.config/quickshell-active"
hl.env("qsDir", qsDir)

-- Default variables
-- Copy these to ~/.config/hypr/custom/variables.lua to make changes in a dotfiles-update-friendly manner

-- The folder within ~/.config/quickshell containing the config
hl.env("qsConfig", "")

-- Apps
-- PULL REQUESTS ADDING MORE WILL NOT BE ACCEPTED, CONFIG FOR YOURSELF
terminal = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'kitty' 'alacritty' 'wezterm' 'konsole' 'kgx' 'uxterm' 'xterm'"
fileManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'nautilus' 'dolphin' 'nemo' 'thunar' 'kitty -1 fish -c yazi'"
browser = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'firefox-nightly' 'firefox' 'google-chrome-stable --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations' 'zen-browser' 'brave' 'chromium' 'microsoft-edge-stable' 'opera' 'librewolf'"
codeEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'windsurf' 'antigravity' 'code' 'codium' 'cursor' 'zed' 'zedit' 'zeditor' 'kate' 'gnome-text-editor' 'emacs' 'command -v nvim && kitty -1 nvim' 'command -v micro && kitty -1 micro'"
officeSoftware = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'wps' 'onlyoffice-desktopeditors' 'libreoffice'"
textEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'kate' 'gnome-text-editor' 'emacs'"
volumeMixer = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'pavucontrol-qt' 'pavucontrol'"
settingsApp = "XDG_CURRENT_DESKTOP=gnome ~/.config/hypr/hyprland/scripts/launch_first_available.sh 'qs -p " .. qsDir .. "/settings.qml' 'systemsettings' 'gnome-control-center' 'better-control'"
taskManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'gnome-system-monitor' 'plasma-systemmonitor --page-name Processes' 'command -v btop && kitty -1 fish -c btop'"

workspaceGroupSize = 10
