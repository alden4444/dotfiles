pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Design tokens. COLORS come live from ~/.config/quickshell/colors.json, which wallust
// rewrites on every theme switch (curated `cs`, dynamic `run`, or builtin `theme`).
// Read through FileView, so value changes hot-reload and the shell restyles WITHOUT a
// restart. Falls back to the Ariadne palette when the file's missing. The non-color
// tokens (spacing / typography / motion) live down here.
Singleton {
    id: root

    FileView {
        path: `${Quickshell.env("HOME")}/.config/quickshell/colors.json`
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: pal
            property string background: "#040e0d"
            property string foreground: "#f5e2c5"
            property string cursor: "#f5e2c5"
            property string color0: "#040e0d"
            property string color1: "#ff6048"
            property string color2: "#7ad9a8"
            property string color3: "#f5cd5b"
            property string color4: "#5fc8d4"
            property string color5: "#e89aa8"
            property string color6: "#3dd1b0"
            property string color7: "#c4b09a"
            property string color8: "#3a1a35"
            property string color9: "#ff6048"
            property string color10: "#7ad9a8"
            property string color11: "#f5cd5b"
            property string color12: "#5fc8d4"
            property string color13: "#e89aa8"
            property string color14: "#3dd1b0"
            property string color15: "#f5e2c5"
        }
    }

    // color helpers
    // Blend two colors (t=0 → a, t=1 → b). We derive the surface shades from the
    // palette this way so they adapt to any scheme, curated or dynamic.
    function mix(a, b, t) {
        return Qt.rgba(a.r * (1 - t) + b.r * t, a.g * (1 - t) + b.g * t, a.b * (1 - t) + b.b * t, 1);
    }
    // Same color at a given alpha (ink/glass derived from fg, so it adapts to light themes).
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
    // Perceived luminance 0..1, used to pick readable ink on the accent.
    function lum(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b; }

    // palette (straight from colors.json)
    readonly property color background: pal.background
    readonly property color foreground: pal.foreground
    readonly property color fg: foreground
    readonly property color accent: pal.color6

    readonly property color red: pal.color1
    readonly property color green: pal.color2
    readonly property color yellow: pal.color3
    readonly property color orange: pal.color3
    readonly property color blue: pal.color4
    readonly property color purple: pal.color5
    readonly property color aqua: pal.color6
    readonly property color grey0: pal.color8
    readonly property color grey2: pal.color7

    // DESIGN.md "Obsidian" token system. Build new UI from these; the legacy
    // tokens below stick around for back-compat 'til every surface is migrated.

    // color roles
    readonly property color accentDeep: Qt.darker(accent, 1.18)          // for pressed/active
    readonly property color onAccent: lum(accent) > 0.55 ? "#0b0b0b" : "#f6f6f6" // readable ink on accent

    // surface fills (base / panel / modal): translucent glass over bg
    readonly property color surfaceBase: mix(background, foreground, 0.04)
    readonly property color surfacePanel: mix(background, foreground, 0.08)
    readonly property color surfaceOverlay: mix(background, foreground, 0.12)

    // ink (text/icon), derived from fg so it adapts to light schemes
    readonly property color inkPrimary: foreground
    readonly property color inkDim: alpha(foreground, 0.60)
    readonly property color inkFaint: alpha(foreground, 0.35)

    // flat fill tints (solid-looking, NOT glass, nothing blurs behind them) +
    // hairline (borders/dividers). Derived from fg so they adapt to light schemes.
    readonly property color fillLow: alpha(foreground, 0.06)
    readonly property color fillHigh: alpha(foreground, 0.13)
    readonly property color hairline: alpha(foreground, 0.14)
    // legacy aliases (pre-flat name); move call sites over to fill* over time
    readonly property color glassLow: fillLow
    readonly property color glassHigh: fillHigh
    // flat translucent black dim behind modals (intentionally not palette-tinted; no blur)
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.5)

    // semantic (used rarely: battery low / errors / destructive confirms)
    readonly property color good: pal.color2
    readonly property color warn: pal.color3
    readonly property color bad: pal.color1

    // layering. Stacked surfaces are told apart by the fill step
    // (surfaceBase → surfacePanel → surfaceOverlay) + a hairline, plus the scrim
    // for modals, never by stacked shadows. The ONE depth cue is a single subtle
    // drop shadow on FLOATING surfaces (the island + popout panels) so they lift
    // off the wallpaper. Tokenized here, used identically everywhere. (No blur, ever.)
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.28)  // floating-surface drop shadow
    readonly property real  shadowBlur: 0.6                 // MultiEffect blur (0..1)
    readonly property int   shadowY: 4                      // vertical offset (px)
    readonly property int   shadowBlurMax: 48               // MultiEffect blurMax (px)

    // radii
    readonly property int rSm: 10     // inner controls
    readonly property int rMd: 14     // cards / inner
    readonly property int rLg: 18     // surfaces / panels
    readonly property int rXl: 24     // Material-You tiles / thick sliders
    readonly property int rPill: 999
    // the floating island's our signature surface, so it gets its own bigger corners
    readonly property int rIsland: 20      // collapsed pill
    readonly property int rIslandOpen: 30  // expanded card

    // spacing (base unit 4)
    readonly property int s1: 4
    readonly property int s2: 8
    readonly property int s3: 12
    readonly property int s4: 16
    readonly property int s5: 24
    readonly property int s6: 32

    // typography
    readonly property string fontDisplay: "SF Mono"  // numerals / data labels
    readonly property string fontBody: "SF Pro Text"            // everything else
    readonly property string fontGlyph: "JetBrainsMono Nerd Font Propo" // nerd-font icons
    readonly property int fontSize: Config.fontSize                 // user-tunable (settings)
    // type scale (relative to fontSize so the settings slider scales it all)
    readonly property int fsDisplay: Math.round(fontSize * 2.4)
    readonly property int fsTitle: Math.round(fontSize * 1.35)
    readonly property int fsHeader: Math.round(fontSize * 1.2)   // menu/section headers, a touch under title
    readonly property real headerTracking: -0.4                  // tightened letter-spacing for headers
    readonly property int fsBody: fontSize
    readonly property int fsLabel: Math.round(fontSize * 0.9)
    readonly property int fsCaption: Math.round(fontSize * 0.78)
    // notch clock, scales with fontSize so the settings slider drives it too
    readonly property int fsClock: fontSize + 1       // collapsed time
    readonly property int fsClockBig: fontSize + 9    // expanded "hero" time
    // weights (400/500 only)
    readonly property int wRegular: 400
    readonly property int wMedium: 500
    readonly property int wSemiBold: 600

    // iconography
    readonly property int iconSize: 18
    readonly property real iconStroke: 1.8

    // motion (flat: critically damped, NO overshoot, matched to Hyprland)
    // spatial (position/size: notch, panels, reflow) ≈ md3_spatial_fast (~387ms)
    readonly property var springBezier: [0.2, 0.0, 0.0, 1.0, 1, 1]   // md3-standard, no overshoot
    readonly property int dSpring: 400
    // effects (opacity/colour: fades, borders) ≈ md3_effects_default (~233ms)
    readonly property var effectsBezier: [0.3, 0.0, 0.0, 1.0, 1, 1]
    readonly property int dEffects: 230
    readonly property int easeOut: Easing.OutCubic       // standard
    readonly property int easeInOut: Easing.InOutCubic
    readonly property int dFast: 140      // micro / hover
    readonly property int dBase: 280
    readonly property int dExpand: 480
    readonly property int dEnter: 600
    readonly property int stagger: 90
    property bool reducedMotion: false
    // collapse durations when reduced motion is on
    function dur(d) { return reducedMotion ? 0 : d; }

    // Legacy tokens (pre-Obsidian), still read by un-migrated components.
    // Migrate each surface to the tokens above, then prune these.
    readonly property color bg0: background
    readonly property color surface: surfaceBase
    readonly property color surfaceRaised: surfacePanel
    readonly property color subtext: inkDim
    readonly property int spacing: s2
    readonly property int radius: rSm
    readonly property string fontFamily: fontBody
    readonly property int animDuration: dFast
}
