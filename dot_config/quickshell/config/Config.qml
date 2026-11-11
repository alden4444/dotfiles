pragma Singleton
import Quickshell
import Quickshell.Io

// User settings, persisted to ~/.config/quickshell/config.json via FileView +
// JsonAdapter. Fields round-trip to JSON on their own; add more as the settings panel
// grows. Live-reloads when something changes the file on disk.
Singleton {
    id: root

    // ── bar / island shape ──
    property alias barHeight: adapter.barHeight
    property alias notchMode: adapter.notchMode               // bar shape: false = floating island, true = flush top notch
    property alias notchFlare: adapter.notchFlare             // px the notch's top corners flare out (concave teardrop); 0 = square
    property alias islandCollapsedWidth: adapter.islandCollapsedWidth // px, the resting pill
    property alias islandExpandedHeight: adapter.islandExpandedHeight // px, hover/pinned height
    property alias islandMinWidth: adapter.islandMinWidth     // px floor; it grows past this to fit the media + date
    property alias islandGap: adapter.islandGap               // px above the floating island (and below, via exclusiveZone)
    property alias islandPadding: adapter.islandPadding       // px of extra inset inside the expanded island
    property alias islandRadius: adapter.islandRadius         // px corner radius, collapsed
    property alias islandRadiusOpen: adapter.islandRadiusOpen // px corner radius, expanded
    property alias hyprGapsOut: adapter.hyprGapsOut           // must match Hyprland general:gaps_out (top)
    property alias gameBarHeight: adapter.gameBarHeight       // px, Game Mode's full-width bar
    property alias gameClusterGap: adapter.gameClusterGap     // px between each card and the clock in bar form

    // ── media (the island's now-playing card) ──
    property alias mediaTitleWidth: adapter.mediaTitleWidth   // px of song name shown before it elides
    property alias mediaArtSize: adapter.mediaArtSize         // px, album art square
    property alias mediaShowAlbum: adapter.mediaShowAlbum     // show the album line
    property alias mediaShowArtist: adapter.mediaShowArtist   // show the artist line
    property alias mediaShowTransport: adapter.mediaShowTransport // show prev / play / next
    property alias mediaScrollSwitch: adapter.mediaScrollSwitch   // scroll over the art to change track

    // ── date knob (the dial under the expanded clock) ──
    property alias dateKnobShow: adapter.dateKnobShow         // show it at all
    property alias dateKnobDays: adapter.dateKnobDays         // how many days on the drum (odd → today centred)
    property alias dateKnobAngle: adapter.dateKnobAngle       // degrees between days around the drum
    property alias dateKnobRadius: adapter.dateKnobRadius     // px drum radius; sets the centre spacing

    // ── clock ──
    property alias clockSeconds: adapter.clockSeconds         // show seconds in the collapsed clock
    property alias clock24h: adapter.clock24h                 // 24-hour vs 12-hour time
    property alias clockViz: adapter.clockViz                 // mini EQ bars beside the collapsed clock while playing

    // ── panel sizes ──
    property alias launcherWidth: adapter.launcherWidth
    property alias launcherRowHeight: adapter.launcherRowHeight
    property alias launcherMaxRows: adapter.launcherMaxRows   // rows visible before it scrolls
    property alias calendarWidth: adapter.calendarWidth
    property alias wallpaperPickerWidth: adapter.wallpaperPickerWidth
    property alias notificationWidth: adapter.notificationWidth
    property alias osdWidth: adapter.osdWidth

    // ── notifications ──
    property alias notifTimeout: adapter.notifTimeout                 // ms a normal popup stays up
    property alias notifTimeoutCritical: adapter.notifTimeoutCritical // ms for urgency=critical
    property alias notifShowBody: adapter.notifShowBody               // show the body text, not just the summary
    property alias notifHistoryHeight: adapter.notifHistoryHeight     // px, history list cap in control center

    // ── osd (volume / brightness pill) ──
    property alias osdTimeout: adapter.osdTimeout             // ms on screen before it hides
    property alias osdBarHeight: adapter.osdBarHeight         // px, level bar thickness
    property alias volumeStep: adapter.volumeStep             // % per key press

    // ── calendar ──
    property alias weekStartsOn: adapter.weekStartsOn         // 0 = Sunday … 6 = Saturday
    property alias calendarCellHeight: adapter.calendarCellHeight
    property alias calendarShowAdjacent: adapter.calendarShowAdjacent // dim the neighbouring months' days

    // ── lock screen ──
    property alias lockBlur: adapter.lockBlur                 // px blur radius over the freeze-frame
    property alias lockDim: adapter.lockDim                   // % scrim over the blur
    property alias lockShotQuality: adapter.lockShotQuality   // grim JPEG quality for the freeze-frame
    property alias lockShowDots: adapter.lockShowDots         // bullets in the password field
    property alias caretBlink: adapter.caretBlink             // ms, password caret blink

    // ── motion ──
    property alias reducedMotion: adapter.reducedMotion       // collapse every duration to 0
    property alias motionSpring: adapter.motionSpring         // ms, position/size moves
    property alias motionEffects: adapter.motionEffects       // ms, fades/colour
    property alias motionFast: adapter.motionFast             // ms, hover micro-interactions
    property alias motionBounce: adapter.motionBounce         // 0-100, spring overshoot on size/position moves

    // ── appearance ──
    property alias fontSize: adapter.fontSize
    property alias theme: adapter.theme
    property alias wallpaper: adapter.wallpaper
    property alias fontBody: adapter.fontBody                 // UI face
    property alias fontDisplay: adapter.fontDisplay           // numerals / clock face
    property alias radiusSmall: adapter.radiusSmall           // inner controls
    property alias radiusMedium: adapter.radiusMedium         // cards
    property alias radiusLarge: adapter.radiusLarge           // panels
    property alias screenCorners: adapter.screenCorners       // paint rounded corners over the display corners
    property alias screenCornerRadius: adapter.screenCornerRadius // px radius of those corners
    property alias surfaceTint: adapter.surfaceTint           // how far the near-black surfaces lift off pure black (%)
    property alias spacingUnit: adapter.spacingUnit           // px base unit; the whole s1..s6 scale derives from it
    property alias iconSize: adapter.iconSize                 // px, global icon size
    property alias iconStroke: adapter.iconStroke             // stroke weight for the drawn icon set (x10)
    property alias hairlineAlpha: adapter.hairlineAlpha       // % borders / dividers
    property alias inkDimAlpha: adapter.inkDimAlpha           // % secondary text
    property alias inkFaintAlpha: adapter.inkFaintAlpha       // % tertiary text
    property alias fillLowAlpha: adapter.fillLowAlpha         // % idle/hover fill
    property alias fillHighAlpha: adapter.fillHighAlpha       // % pressed/selected fill
    property alias scrimOpacity: adapter.scrimOpacity         // % modal backdrop dim
    property alias shadowOpacity: adapter.shadowOpacity       // floating-surface drop shadow (%)
    property alias shadowBlur: adapter.shadowBlur             // %
    property alias shadowOffsetY: adapter.shadowOffsetY       // px
    property alias shadowSpread: adapter.shadowSpread         // px, MultiEffect blurMax

    // ── control center sizing ──
    property alias ccTileHeight: adapter.ccTileHeight
    property alias ccRowHeight: adapter.ccRowHeight           // wifi / bluetooth / audio device rows
    property alias ccMediaHeight: adapter.ccMediaHeight       // now-playing card

    // ── system ──
    property alias brightnessStep: adapter.brightnessStep     // % per key press
    property alias brightnessPoll: adapter.brightnessPoll     // ms between internal-backlight reads
    property alias batteryLowThreshold: adapter.batteryLowThreshold // % at which battery reads "low"
    property alias nightLightTemp: adapter.nightLightTemp     // Kelvin
    property alias wallpaperFade: adapter.wallpaperFade       // ms crossfade when the wallpaper changes

    // Control center layout (all editable from the settings panel)
    property alias ccColumns: adapter.ccColumns            // grid width
    property alias ccSliders: adapter.ccSliders            // show the volume/brightness sliders
    property alias ccMedia: adapter.ccMedia                // show the now-playing media card
    property alias ccNotifications: adapter.ccNotifications// show the notifications section
    property alias ccTiles: adapter.ccTiles                // JSON [{key,span,enabled}]: stored order + overrides

    // The canonical quick-settings tiles. The CODE owns what tiles EXIST and each one's
    // default size; the stored ccTiles only carries the user's order + overrides. So a
    // tile you add here later just shows up on its own (appended, enabled). To add one:
    // drop an entry here plus a case in ControlCenterContent's delegate, and that's it.
    readonly property var ccRegistry: [
        { key: "wifi",       label: "Wi-Fi",       span: 2 },
        { key: "audio",      label: "Audio",       span: 2 },
        { key: "bluetooth",  label: "Bluetooth",   span: 2 },
        { key: "display",    label: "Display",     span: 2 },
        { key: "peace",      label: "Peace",       span: 1 },
        { key: "nightlight", label: "Night Light", span: 1 }
    ]
    function _ccReg(key) {
        for (let i = 0; i < ccRegistry.length; i++)
            if (ccRegistry[i].key === key) return ccRegistry[i];
        return null;
    }

    // The resolved, ordered tile layout: stored order/overrides first (unknown keys get
    // dropped), then any registry tiles not stored yet. Shape is [{key,label,span,enabled}].
    readonly property var ccLayout: {
        let stored = [];
        try { stored = JSON.parse(ccTiles || "[]"); } catch (e) { stored = []; }
        const out = [];
        const seen = ({});
        for (let i = 0; i < stored.length; i++) {
            const s = stored[i];
            if (!s) continue;
            const reg = _ccReg(s.key);
            if (!reg || seen[s.key]) continue;
            seen[s.key] = true;
            out.push({ key: s.key, label: reg.label,
                       span: (s.span === 1 || s.span === 2) ? s.span : reg.span,
                       enabled: s.enabled !== false });
        }
        for (let i = 0; i < ccRegistry.length; i++) {
            const r = ccRegistry[i];
            if (seen[r.key]) continue;
            out.push({ key: r.key, label: r.label, span: r.span, enabled: true });
        }
        return out;
    }
    // the tiles that actually render, in order
    readonly property var ccVisibleTiles: ccLayout.filter(t => t.enabled)

    function _ccClone() {
        return ccLayout.map(t => ({ key: t.key, span: t.span, enabled: t.enabled }));
    }
    function _ccPersist(arr) { ccTiles = JSON.stringify(arr); }

    function ccSetEnabled(key, on) {
        const a = _ccClone();
        for (let i = 0; i < a.length; i++) if (a[i].key === key) a[i].enabled = on;
        _ccPersist(a);
    }
    function ccSetSpan(key, span) {
        const a = _ccClone();
        for (let i = 0; i < a.length; i++) if (a[i].key === key) a[i].span = span;
        _ccPersist(a);
    }
    function ccMove(key, dir) {
        const a = _ccClone();
        let i = -1;
        for (let j = 0; j < a.length; j++) if (a[j].key === key) { i = j; break; }
        if (i < 0) return;
        const t = i + dir;
        if (t < 0 || t >= a.length) return;
        const tmp = a[i]; a[i] = a[t]; a[t] = tmp;
        _ccPersist(a);
    }



    FileView {
        path: `${Quickshell.env("HOME")}/.config/quickshell-active/config.json`
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter() // persist changes back to disk (e.g. a wallpaper pick)

        JsonAdapter {
            id: adapter
            // bar / island
            property int barHeight: 32
            property bool notchMode: false
            property int notchFlare: 14
            property int islandCollapsedWidth: 150
            property int islandExpandedHeight: 120
            property int islandMinWidth: 500
            property int islandGap: 8
            property int islandPadding: 2
            property int islandRadius: 20
            property int islandRadiusOpen: 30
            property int hyprGapsOut: 15
            property int gameBarHeight: 50
            property int gameClusterGap: 180
            // media
            property int mediaTitleWidth: 104
            property int mediaArtSize: 90
            property bool mediaShowAlbum: true
            property bool mediaShowArtist: true
            property bool mediaShowTransport: true
            property bool mediaScrollSwitch: true
            // date knob
            property bool dateKnobShow: true
            property int dateKnobDays: 7
            property int dateKnobAngle: 22
            property int dateKnobRadius: 92
            // clock
            property bool clockSeconds: false
            property bool clock24h: true
            property bool clockViz: true
            // panels
            property int launcherWidth: 560
            property int launcherRowHeight: 48
            property int launcherMaxRows: 7
            property int calendarWidth: 360
            property int wallpaperPickerWidth: 1040
            property int notificationWidth: 480
            property int osdWidth: 300
            // notifications
            property int notifTimeout: 2000
            property int notifTimeoutCritical: 6000
            property bool notifShowBody: true
            property int notifHistoryHeight: 200
            // osd
            property int osdTimeout: 1500
            property int osdBarHeight: 8
            property int volumeStep: 5
            // calendar
            property int weekStartsOn: 0
            property int calendarCellHeight: 32
            property bool calendarShowAdjacent: true
            // lock
            property int lockBlur: 64
            property int lockDim: 22
            property int lockShotQuality: 85
            property bool lockShowDots: false
            property int caretBlink: 580
            // motion
            property bool reducedMotion: false
            property int motionSpring: 400
            property int motionEffects: 230
            property int motionFast: 140
            property int motionBounce: 56
            // appearance
            property int fontSize: 14
            property string theme: "dark"
            property string wallpaper: ""
            property string fontBody: "SF Pro Text"
            property string fontDisplay: "Manrope"
            property int radiusSmall: 10
            property int radiusMedium: 14
            property int radiusLarge: 18
            property bool screenCorners: true
            property int screenCornerRadius: 14
            property int surfaceTint: 4          // % ; surfaceBase step off black
            property int spacingUnit: 4
            property int iconSize: 18
            property int iconStroke: 22          // x10 (2.2)
            property int hairlineAlpha: 14       // %
            property int inkDimAlpha: 60         // %
            property int inkFaintAlpha: 35       // %
            property int fillLowAlpha: 6         // %
            property int fillHighAlpha: 13       // %
            property int scrimOpacity: 50        // %
            property int shadowOpacity: 55       // %
            property int shadowBlur: 100         // %
            property int shadowOffsetY: 8
            property int shadowSpread: 80
            // control center sizing
            property int ccTileHeight: 64
            property int ccRowHeight: 40
            property int ccMediaHeight: 148
            // system
            property int brightnessStep: 5
            property int brightnessPoll: 2000
            property int batteryLowThreshold: 20
            property int nightLightTemp: 3000
            property int wallpaperFade: 450
            // control center
            property int ccColumns: 4
            property bool ccSliders: true
            property bool ccMedia: true
            property bool ccNotifications: true
            property string ccTiles: ""
        }
    }
}
