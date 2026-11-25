-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples

hl.workspace_rule({ workspace = "1", monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1", default = true })

-- Prevent idle/lockscreen/sleep while BeamNG.drive (BeamMP) is open
hl.window_rule({ match = { class = "^(BeamNG\\.drive)$" }, idle_inhibit = "always" })

