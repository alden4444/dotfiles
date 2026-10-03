hl.on("hyprland.start", function ()

    -- Sync environment smoothly now that a valid DBus session exists
    -- Hardcoding =Hyprland on both ensures systemd and DBus are completely aligned
    hl.exec_cmd("export qsDir=" .. qsDir .. " XDG_CURRENT_DESKTOP=Hyprland XCURSOR_THEME=Bibata-Modern-Ice XCURSOR_SIZE=20 HYPRCURSOR_THEME=Bibata-Modern-Ice HYPRCURSOR_SIZE=20; dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP qsDir XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE")
    hl.exec_cmd("export qsDir=" .. qsDir .. " XDG_CURRENT_DESKTOP=Hyprland XCURSOR_THEME=Bibata-Modern-Ice XCURSOR_SIZE=20 HYPRCURSOR_THEME=Bibata-Modern-Ice HYPRCURSOR_SIZE=20; systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP qsDir XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE")
    
    -- Clear Vulkan driver variables to prevent Chromium/Chrome launch timeouts
    hl.exec_cmd("systemctl --user set-environment VK_DRIVER_FILES=")

    -- Atomically update ~/.config/quickshell-active to point to qsDir if qsDir is a separate folder
    if qsDir ~= HOME .. "/.config/quickshell-active" then
        os.execute("ln -sfn " .. qsDir .. " " .. HOME .. "/.config/quickshell-active")
    end


    -- Set up wlogout symlink if quickshell has a wlogout config
    if is_file_exists(qsDir .. "/wlogout/layout") then
        os.execute("rm -rf " .. HOME .. "/.config/wlogout && ln -sf " .. qsDir .. "/wlogout " .. HOME .. "/.config/wlogout")
    end

    -- Bar, wallpaper
    hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
    hl.exec_cmd("qs -p " .. qsDir)

    -- Core components (authentication, lock screen, notification daemon)
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("export qsDir=" .. qsDir .. "; pgrep -x hypridle || hypridle")

    -- Audio
    hl.exec_cmd("easyeffects --hide-window --service-mode")

    -- Clipboard: history
    hl.exec_cmd("wl-paste --type text --watch bash -c 'cliphist store && qs -p " .. qsDir .. " ipc call cliphistService update'")
    hl.exec_cmd("wl-paste --type image --watch bash -c 'cliphist store && qs -p " .. qsDir .. " ipc call cliphistService update'")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 20")
end)
