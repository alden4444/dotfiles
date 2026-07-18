#!/usr/bin/env bash
# Update VSCodium theme from Kitty and/or Matugen colors

set -euo pipefail

KITTY_COLORS="$HOME/.config/kitty/colors/wallust.conf"
MATUGEN_COLORS="$HOME/.local/state/quickshell/user/generated/colors.json"

VSCFG_VSCodium="$HOME/.config/VSCodium/User/settings.json"
VSCFG_Antigravity="$HOME/.config/Antigravity IDE/User/settings.json"

# Check that at least one settings file exists
if [ ! -f "$VSCFG_VSCodium" ] && [ ! -f "$VSCFG_Antigravity" ]; then
    echo "Neither VSCodium nor Antigravity IDE settings.json found" >&2
    exit 1
fi

mode="${1:-}"

# Fallback: check if we should guess mode based on what exists
if [ -z "$mode" ]; then
    if [ -f "$MATUGEN_COLORS" ]; then
        mode="matugen"
    elif [ -f "$KITTY_COLORS" ]; then
        mode="wallust"
    else
        echo "No color files found!" >&2
        exit 1
    fi
fi

# Initialize colors
BG=""
FG=""
CURSOR=""
COLOR0=""
COLOR1=""
COLOR2=""
COLOR3=""
COLOR4=""
COLOR5=""
COLOR6=""
COLOR7=""
COLOR8=""
COLOR9=""
COLOR10=""
COLOR11=""
COLOR12=""
COLOR13=""
COLOR14=""
COLOR15=""

# Load Kitty colors (matches kitty theme exactly)
if [ -f "$KITTY_COLORS" ]; then
    while read -r key val _; do
        # Ignore comments, empty lines, or lines without values
        [[ "$key" =~ ^# || -z "$key" || -z "$val" ]] && continue
        # Store in W_ variables
        eval "W_$key=\"$val\""
    done < "$KITTY_COLORS"
else
    # Fallback default ANSI colors
    W_background="#1C1E26"; W_foreground="#D5D8DA"; W_cursor="#26BBD9"
    W_color0="#1C1E26"; W_color1="#E95678"; W_color2="#29D398"; W_color3="#FAC29A"
    W_color4="#26BBD9"; W_color5="#EE64AE"; W_color6="#59E3E3"; W_color7="#9DA0A2"
    W_color8="#2E303E"; W_color9="#E95678"; W_color10="#29D398"; W_color11="#FAC29A"
    W_color12="#26BBD9"; W_color13="#EE64AE"; W_color14="#59E3E3"; W_color15="#D5D8DA"
fi

if [ "$mode" = "matugen" ] && [ -f "$MATUGEN_COLORS" ]; then
    # Load Matugen colors
    eval "$(jq -r 'to_entries | .[] | "M_\(.key)=\(.value)"' "$MATUGEN_COLORS")"
    
    BG="$M_background"
    FG="$M_on_surface"
    CURSOR="$M_primary"
    
    SB_BG="$M_surface_container_low"
    SB_FG="$M_on_surface_variant"
    SB_HDR="$M_surface_container"
    AB_BG="$M_surface_container_lowest"
    AB_FG="$M_primary"
    AB_INACTIVE="$M_on_surface_variant"
    ST_BG="$M_surface_container_lowest"
    ST_FG="$M_on_surface"
    TB_BG="$M_background"
    TB_FG="$M_on_surface"
    GH_BG="$M_surface_container_low"
    TAB_ACT_BG="$M_background"
    TAB_ACT_FG="$M_on_surface"
    TAB_INACT_BG="$M_surface_container_low"
    TAB_INACT_FG="$M_on_surface_variant"
    LN_FG="$M_outline"
    LN_ACT_FG="$M_primary"
else
    # Default to Wallust (Kitty Colors)
    BG="$W_background"
    FG="$W_foreground"
    CURSOR="$W_cursor"
    
    SB_BG="$W_color0"
    SB_FG="$W_foreground"
    SB_HDR="$W_color8"
    AB_BG="$W_background"
    AB_FG="$W_cursor"
    AB_INACTIVE="$W_color7"
    ST_BG="$W_color0"
    ST_FG="$W_foreground"
    TB_BG="$W_background"
    TB_FG="$W_foreground"
    GH_BG="$W_color0"
    TAB_ACT_BG="$W_background"
    TAB_ACT_FG="$W_foreground"
    TAB_INACT_BG="$W_color0"
    TAB_INACT_FG="$W_color7"
    LN_FG="$W_color8"
    LN_ACT_FG="$W_cursor"
fi

# Create a JSON payload of workbench.colorCustomizations (no terminal configuration)
customizations=$(jq -n \
  --arg bg "$BG" \
  --arg fg "$FG" \
  --arg cursor "$CURSOR" \
  --arg sb_bg "$SB_BG" \
  --arg sb_fg "$SB_FG" \
  --arg sb_hdr "$SB_HDR" \
  --arg ab_bg "$AB_BG" \
  --arg ab_fg "$AB_FG" \
  --arg ab_inactive "$AB_INACTIVE" \
  --arg st_bg "$ST_BG" \
  --arg st_fg "$ST_FG" \
  --arg tb_bg "$TB_BG" \
  --arg tb_fg "$TB_FG" \
  --arg gh_bg "$GH_BG" \
  --arg tab_act_bg "$TAB_ACT_BG" \
  --arg tab_act_fg "$TAB_ACT_FG" \
  --arg tab_inact_bg "$TAB_INACT_BG" \
  --arg tab_inact_fg "$TAB_INACT_FG" \
  --arg ln_fg "$LN_FG" \
  --arg ln_act_fg "$LN_ACT_FG" \
  '{
    "editor.background": $bg,
    "editor.foreground": $fg,
    "editorGutter.background": $bg,
    "editor.lineHighlightBackground": ($cursor + "15"),
    "editor.lineHighlightBorder": "#00000000",
    "sideBar.background": $sb_bg,
    "sideBar.foreground": $sb_fg,
    "sideBarSectionHeader.background": $sb_hdr,
    "activityBar.background": $ab_bg,
    "activityBar.foreground": $ab_fg,
    "activityBar.inactiveForeground": $ab_inactive,
    "statusBar.background": $st_bg,
    "statusBar.foreground": $st_fg,
    "titleBar.activeBackground": $tb_bg,
    "titleBar.activeForeground": $tb_fg,
    "editorGroupHeader.tabsBackground": $gh_bg,
    "tab.activeBackground": $tab_act_bg,
    "tab.activeForeground": $tab_act_fg,
    "tab.inactiveBackground": $tab_inact_bg,
    "tab.inactiveForeground": $tab_inact_fg,
    "editorCursor.foreground": $cursor,
    "editorLineNumber.foreground": $ln_fg,
    "editorLineNumber.activeForeground": $ln_act_fg
  }')

# Safely update settings files
for cfg in "$VSCFG_VSCodium" "$VSCFG_Antigravity"; do
    if [ -f "$cfg" ]; then
        tmp="$(mktemp)"
        jq --argjson cust "$customizations" '.["workbench.colorCustomizations"] = $cust' "$cfg" > "$tmp"
        mv "$tmp" "$cfg"
    fi
done
