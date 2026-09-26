import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme"
import "../../config"
import "../../services"
import "../../components"
import "../launcher"
import "../controlcenter"
import "../notifications"
import "../osd"
import "../wallpaper"
import "../theme"
import "../logout"
import "../polkit"
import "../calendar"
import "../media"

// The notch (one per screen): a "dynamic island" that floats below the top edge
// (small gap above and below, all corners rounded, subtle shadow, the only bit of
// depth we let in). Collapsed it's just the clock, with a mini accent EQ viz that
// animates in only while music's playing (viz + clock stay centered as a group).
// Hover or click-to-pin springs it open to a media player (left), clock + date
// (center), and a control-center pill (right). Every size/radius/motion comes
// from Theme tokens. Modelled on notch-bar.html.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "quickshell:bar"
    anchors { top: true; left: true; right: true }
    // Reserve a strip so windows tile BELOW the island, with the gap under the
    // (collapsed) island matching the gap above it (topGap). Hyprland piles gaps_out
    // on top of the reserved edge, so subtract it or the two stack and the window
    // sits too far down. The wallpaper ignores this (fills the screen → no band).
    exclusionMode: ExclusionMode.Normal
    // game bar reserves its full height at the very top (no gap); otherwise reserve the
    // floating-island strip (gap above and below the collapsed island).
    // notch: no gap above (flush), so reserve just the notch height + the below gap.
    readonly property bool barShown: GlobalState.barVisible || morphWanted || osdWanted || notifWanted
    visible: barShown

    exclusiveZone: (!barShown || !GlobalState.barVisible) ? 0
                 : barForm ? gameBarH
                 : notchMode ? Math.max(0, topGap + collapsedH - gapsOut)
                 : Math.max(0, topGap * 2 + collapsedH - gapsOut)
    // Full-height ALWAYS: transparent and click-through via the mask except for the
    // island. Resizing the window on open (116 → full) is what gave us the morph flash,
    // 'cause the layer-surface reconfigure briefly yanked the island upward before it
    // settled. Keep it a constant size and opening the launcher never reconfigures the
    // window. Still anchored top/left/right (never bottom) so the exclusiveZone keeps
    // reserving only the strip and tiled windows sit below the island.
    implicitHeight: modelData?.height ?? 1600
    color: "transparent"
    // EXCLUSIVE keyboard focus while a panel's open so keystrokes stay with the
    // launcher/CC even under focus-follows-mouse (OnDemand let the pointer steal focus).
    WlrLayershell.keyboardFocus: morphWanted ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // input mask: the morph backdrop (click-outside) when a panel's open, else the bar
    // itself. In Game Mode a tall transient projects below the bar, so union in the
    // transientHost too, or clicks on the overflowing part fall through to the window
    // behind it.
    mask: Region {
        item: morphWanted ? backdrop : notch
        Region { item: (!bar.morphWanted && transientHost.shown) ? transientHost : null }
        Region { item: statusPill.visible ? statusPill : null }
        Region { item: artPill.visible ? artPill : null }
        Region { item: islandZone }
        Region { item: statusPill.visible ? statusZone : null }
        Region { item: artPill.visible ? artZone : null }
    }

    property bool pinned: false
    // Hover no longer opens the island: it PRESENTS it. The collapsed pill steps forward
    // (a little wider and taller, a few px further down from the edge, the two circles
    // nudged outward) as an invitation; a click on it then opens the expanded island, and
    // another click closes it. `presenting` is a stepped state so the notch's own
    // width/height springs carry the size; `presentT` is the same spring as a 0..1 clock
    // for the things that have no Behavior of their own (the top margin, the circles' x),
    // and it stays at 1 while the island is open (see `staged`).
    readonly property bool expanded: pinned
    readonly property bool presenting: hover.hovered && !pinned
    // the stage position (dropped from the edge, circles pushed out) holds through the
    // click and through EVERY form the island takes: the open island, every panel morph
    // (launcher, CC, pickers, calendar, logout, polkit) and the transients (OSD,
    // notifications) all sit centre stage. Only the resting pill lines up with the
    // circles; the game bar is full width and takes no stage at all.
    readonly property bool staged: (presenting || pinned || islandMorph || osdWanted || notifWanted) && !barForm
    property real presentT: staged ? 1 : 0
    Behavior on presentT { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
    // One knob (Settings: "Stage lift", px) scales the whole effect; the rest keep their
    // proportions to it.
    readonly property real stage: Config.islandStage
    readonly property real presentGrowW: stage * 2.4   // px wider while presenting
    readonly property real presentGrowH: stage         // px taller
    readonly property real presentDrop: stage          // px further down from the top edge
    readonly property real presentPush: stage          // px each circle moves outward (on top of the half-growth)
    // the circles present themselves the same way on their own hover: they grow (scale,
    // about their centre), push out away from the island and drop. The drop is the
    // island's drop plus half the growth, so a presented circle's TOP edge lands exactly
    // where a presented island's does: only when all three are on stage do they share a
    // top line; a resting neighbour sits visibly higher.
    readonly property real circlePush: stage * 1.2
    readonly property real circleScale: 1 + stage * 0.016
    readonly property real circleDrop: presentDrop + collapsedH * (circleScale - 1) / 2

    // ── panels out of the circles ──
    // With the status circle on, the control center grows OUT OF THE CIRCLE, right where the
    // circle sits (pulled away from the island on its hover), whoever opens it (click,
    // keybind, IPC); the media player does the same out of the art circle, mirrored. The
    // island is NOT touched: it keeps its own form and content. Each circle has its own host
    // (`SatHost`, one per side, so both panels can be up at once): it draws its own fill and
    // springs from the circle's rect to the panel's rect on ONE clock, its top corner on the
    // circle's outer top corner (clamped to the screen); the circle hides its disc (the fill
    // draws exactly there from frame one) and lends its glyphs (they cross-fade out on top of
    // the growing fill). Closing is the same path backwards; the disc comes back only when
    // the spring has actually finished (#35). The panel's width AND height are sampled at
    // the open and held through the close: the live morph width flips back to the launcher's
    // the instant a panel stops being wanted, and the media player used to widen towards it
    // before shrinking.
    readonly property bool ccFromPill: ccWanted && Config.statusPill && !barForm
    readonly property bool mediaFromPill: mediaWanted && Config.artPill && Media.hasPlayer && !barForm
    // the island can only morph into one thing: an island-hosted panel closes the other
    onCcWantedChanged: if (ccWanted && !(Config.statusPill && !barForm)) GlobalState.mediaPlayerOpen = false
    onMediaWantedChanged: if (mediaWanted && !(Config.artPill && Media.hasPlayer && !barForm)) GlobalState.controlCenterOpen = false
    function lerp(a, b, t) { return a + (b - a) * t; }
    // the island's stage geometry, shared by the notch and both hosts so they can never
    // drift: horizontal centre offset and top margin
    readonly property real stageX: -pillShift
    readonly property real stageTop: restTop
    readonly property real restTop: topGap * (1 - flushT) + presentDrop * presentT * (1 - notchT)
    readonly property bool playing: Media.player?.isPlaying ?? false

    // When a panel closes with the cursor still over its (tall) area, the hover handler
    // would immediately report hovered → the island would flash its expanded/hover state
    // before shrinking below the cursor. Suppress hover for the collapse animation so it
    // drops straight to the collapsed notch/island instead; a fresh hover afterwards works.
    property bool closeGuard: false
    Timer { id: closeGuardTimer; interval: Theme.dur(Theme.dSpring) + 80; onTriggered: bar.closeGuard = false }
    onMorphWantedChanged: if (!morphWanted) { closeGuard = true; closeGuardTimer.restart(); }

    // launcher state: the island ITSELF morphs into the launcher, no extra layer
    readonly property bool onFocusedMon: (Hyprland.focusedMonitor?.name ?? "") === (modelData?.name ?? "x")
    // polkit (privilege escalation) is the top-priority morph: the agent drives it (not
    // a GlobalState toggle), and it SUPPRESSES the other panels so nothing open can ever
    // overlap an auth prompt.
    readonly property bool polkitWanted: Polkit.active && onFocusedMon
    readonly property bool launcherWanted: GlobalState.launcherOpen && onFocusedMon && !polkitWanted
    readonly property bool ccWanted: GlobalState.controlCenterOpen && onFocusedMon && !polkitWanted
    readonly property bool wallpaperWanted: GlobalState.wallpaperPickerOpen && onFocusedMon && !polkitWanted
    readonly property bool themeWanted: GlobalState.themeSwitcherOpen && onFocusedMon && !polkitWanted
    readonly property bool logoutWanted: GlobalState.logoutOpen && onFocusedMon && !polkitWanted
    readonly property bool calendarWanted: GlobalState.calendarOpen && onFocusedMon && !polkitWanted
    readonly property bool mediaWanted: GlobalState.mediaPlayerOpen && onFocusedMon && !polkitWanted
    // any of these panels morphs the island; the window's full-height already, so this
    // just drives keyboard focus + the click-outside backdrop + the input mask.
    readonly property bool morphWanted: polkitWanted || launcherWanted || ccWanted || wallpaperWanted || themeWanted || logoutWanted || calendarWanted || mediaWanted
    // the subset that morphs the ISLAND itself: the control center leaves the island alone
    // when it grows out of the status circle instead (ccFromPill). One expression, so the
    // notch never sees an in-between frame where the CC counts as an island morph.
    readonly property bool islandMorph: polkitWanted || launcherWanted || (ccWanted && !(Config.statusPill && !barForm)) || wallpaperWanted || themeWanted || logoutWanted || calendarWanted
        || (mediaWanted && !(Config.artPill && Media.hasPlayer && !barForm))
    // a volume/brightness change morphs the island into a level pill (auto-hide), on the
    // monitor the OSD fired for. Beats a notification ('cause that's direct feedback to a
    // keypress), but never beats launcher/CC, those own the island.
    readonly property bool osdWanted: !morphWanted && OsdState.active && OsdState.screen === (modelData?.name ?? "")
    // a transient notification morphs the island to show it (auto-dismiss), but only
    // when idle (nothing else up: launcher/CC/OSD) and on the focused monitor.
    readonly property bool notifWanted: !morphWanted && !osdWanted && onFocusedMon && Notifications.showing !== null
    // Game Mode flattens the floating island into a full-width thin TOP BAR (squared,
    // edge-anchored, no gap) with a centred media | clock | cc cluster. It STAYS a bar
    // through everything, no morph-back flash. An OSD / notification / mode indicator
    // shows centred IN the bar (the cluster yields to it, the bar never shrinks back to
    // an island), and the morph panels (launcher, CC, pickers, settings, power, polkit)
    // float BELOW the bar via morphHost instead of expanding it. So barForm tracks Game
    // Mode alone; the osd/notif/morph states layer on top of it.
    readonly property bool barForm: GameMode.enabled
    // Notch mode: instead of the floating island, the bar hangs flush from the top edge
    // with SQUARE top corners and a ROUNDED bottom (a hardware-notch look). Toggled from
    // settings (Config.notchMode). Game Mode's full-width bar still wins over it.
    readonly property bool notchMode: Config.notchMode && !barForm

    // ── shape morph clocks ────────────────────────────────────────────────────────────────
    // Switching island↔notch used to hard-swap two different fills (a rounded Rectangle and
    // the teardrop Shape) via `visible`, so one popped out as the other popped in while the
    // geometry animated underneath — that was the chop. Now there's ONE shape that morphs,
    // driven by these. Everything positional reads them too, so the whole switch runs off a
    // single clock and nothing steps.
    property real notchT: notchMode ? 1 : 0        // 0 = island, 1 = notch
    Behavior on notchT { enabled: bar.morphAnim; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
    // Entering Game Mode is INSTANT: it's the "give me frames" switch, so the bar just appears
    // (Theme.dur() is already 0 by then anyway) and this latch drops the morph Behaviors so
    // nothing animates on the way in. LEAVING is not latched — game mode is off, so the shell
    // is back to normal immediately, shadows and all, and the bar animates down to the island
    // the way every other morph does.
    property bool morphAnim: true
    onBarFormChanged: if (barForm) { morphAnim = false; morphAnimTimer.restart(); }
    Timer { id: morphAnimTimer; interval: 90; onTriggered: bar.morphAnim = true }
    property real barT: barForm ? 1 : 0            // 0 = island/notch, 1 = game bar
    // satellites: the status circle (right, on by knob) and the art circle (left, while
    // a music player is open). The island and whichever circles are showing centre as ONE group: the
    // island slides by half the footprint (circle + gap) of the right one minus the left
    // one, so with both up the clock sits exactly where it would with neither. Each circle
    // has its own spring clock so it glides in and out; the game bar is full width and
    // takes no shift at all.
    property real pillT: Config.statusPill ? 1 : 0
    Behavior on pillT { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
    property real artT: (Config.artPill && Media.hasPlayer) ? 1 : 0
    Behavior on artT { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
    readonly property real pillShift: (collapsedH + topGap) / 2 * (pillT - artT) * (1 - barT)
    Behavior on barT { enabled: bar.morphAnim; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
    // how "flush to the top edge" we are; both the notch and the game bar sit flush. Derived,
    // so it's already continuous — giving it its own Behavior would just chase a moving target.
    readonly property real flushT: Math.max(barT, notchT)

    // notch bottom radius (clamped to fit the current height) and the effective flare
    // (concave top-corner radius), clamped so the arcs always fit no matter the state.
    // real, not int: notch.rad interpolates continuously with the height, so rounding these to
    // whole px would re-quantize the corner into visible 1px jumps mid-animation.
    readonly property real notchBR: Math.min(notch.rad, notch.height / 2)
    readonly property real notchFlareRaw: Math.max(0, Math.min(Config.notchFlare, notch.height - notchBR, notch.width / 2))
    // TWO-PHASE morph, so the outline is well defined at every frame instead of trying to be a
    // rounded top and a flared top at once: for t<0.5 the top corners un-round, for t>0.5 the
    // flares grow out. Midpoint is a plain square-top / round-bottom slab, which reads fine.
    readonly property real notchFlareEff: notchFlareRaw * Math.max(0, 2 * notchT - 1)
    readonly property real notchTopR: notch.rad * Math.max(0, 1 - 2 * notchT)

    // SVG outline covering BOTH forms: rounded-top island (fr = 0, tr > 0) through to the
    // flared notch (fr > 0, tr = 0), with a rounded bottom either way. Local coords; the body
    // sits at x∈[fr, W-fr] and the flares stick out `fr` past each side at the top edge.
    // Radii near zero degrade to straight lines (a zero-radius SVG arc is undefined).
    function notchPath(bw, h, tr, br, fr) {
        var W = bw + 2 * fr;
        var L = fr, R = W - fr;
        var eps = 0.01;
        var p;
        // top-left: flare out, round in, or a hard corner
        if (fr > eps)      p = "M 0,0 A " + fr + "," + fr + " 0 0 1 " + L + "," + fr;
        else if (tr > eps) p = "M " + L + "," + tr;
        else               p = "M " + L + ",0";
        // left side down, across the bottom, back up the right
        if (br > eps) {
            p += " L " + L + "," + (h - br);
            p += " A " + br + "," + br + " 0 0 0 " + (L + br) + "," + h;
            p += " L " + (R - br) + "," + h;
            p += " A " + br + "," + br + " 0 0 0 " + R + "," + (h - br);
        } else {
            p += " L " + L + "," + h + " L " + R + "," + h;
        }
        // top-right, mirroring the top-left
        if (fr > eps) {
            p += " L " + R + "," + fr;
            p += " A " + fr + "," + fr + " 0 0 1 " + W + ",0";
        } else if (tr > eps) {
            p += " L " + R + "," + tr;
            p += " A " + tr + "," + tr + " 0 0 0 " + (R - tr) + ",0";
            p += " L " + (L + tr) + ",0";
            p += " A " + tr + "," + tr + " 0 0 0 " + L + "," + tr;
        } else {
            p += " L " + R + ",0";
        }
        return p + " Z";
    }
    readonly property int gameBarH: Config.gameBarHeight
    readonly property int gameClusterGap: Config.gameClusterGap // gap between each card and the clock in bar form

    readonly property int topGap: Config.islandGap  // gap above the island (and below it too, via exclusiveZone)
    readonly property int gapsOut: Config.hyprGapsOut // must match Hyprland general:gaps_out (top); subtract it or it stacks
    readonly property int collapsedW: Config.islandCollapsedWidth
    readonly property int collapsedH: Math.max(34, Config.barHeight + 4)
    // The expanded island FITS the clock: the barRow side insets + the clock box, which is as
    // wide as the bigger of the scaled time and the date strip (the same expression clockBtn
    // settles to, minus its width Behavior) + a little breathing room. Both are content-driven
    // (TextMetrics, month label + day cells), never derived from the island width, so there's
    // no binding loop back into this.
    readonly property int expandedContentW:
          2 * (Theme.s3 + Config.islandPadding)         // barRow left+right insets at full expand
        + Math.max(timeRow.width * (Theme.fsClockBig / Theme.fsClock), dateStrip.width) + Theme.s4
        + Theme.s4                                      // breathing room
    readonly property int expandedW: expandedContentW
    readonly property int expandedH: Config.islandExpandedHeight
    readonly property int launcherW: Config.launcherWidth
    readonly property int calendarW: Config.calendarWidth       // the calendar's a compact morph
    readonly property int mediaW: Config.mediaPlayerWidth       // the media player card
    readonly property int wallpaperW: Config.wallpaperPickerWidth // wallpaper picker wants room for big previews
    readonly property int themeW: Config.themeSwitcherWidth     // landscape strip of theme previews, wants width not height
    readonly property int polkitW: 460                          // the auth prompt: one column, no room needed for a grid
    readonly property int morphW: polkitWanted ? polkitW : calendarWanted ? calendarW : mediaWanted ? mediaW : wallpaperWanted ? wallpaperW : themeWanted ? themeW : launcherW
    readonly property int notifW: Config.notificationWidth
    readonly property int osdW: Config.osdWidth

    // click-outside dismiss while the launcher's open (full-window, behind the island)
    MouseArea {
        id: backdrop
        anchors.fill: parent
        enabled: bar.morphWanted
        onClicked: {
            // polkit: click-outside CANCELS the auth request (fail closed), never a quiet close
            if (bar.polkitWanted) { if (Polkit.flow) Polkit.flow.cancelAuthenticationRequest(); return; }
            GlobalState.launcherOpen = false;
            GlobalState.controlCenterOpen = false;
            GlobalState.wallpaperPickerOpen = false;
            GlobalState.themeSwitcherOpen = false;
            GlobalState.logoutOpen = false;
            GlobalState.calendarOpen = false;
            GlobalState.mediaPlayerOpen = false;
        }
    }

    // Hover zones: STATIC rects covering each surface at rest AND on stage. Hovering moves
    // the surface (drop, push, growth), so a handler riding the surface itself gets left
    // behind by the cursor at a liminal edge: un-hover, the surface comes back under the
    // cursor, hover, and so on, vigorously (seen on all three). A union rect that does not
    // move with its own effect cannot be left behind. Each zone is exactly the surface's
    // presented footprint; at rest that reads a little generous around the edges.
    Item {
        id: islandZone
        x: bar.width / 2 + bar.stageX - width / 2
        y: bar.topGap
        width: bar.collapsedW + bar.presentGrowW
        height: bar.collapsedH + bar.presentGrowH + bar.presentDrop
        HoverHandler { id: hover; enabled: !bar.morphWanted && !bar.notifWanted && !bar.osdWanted && !bar.barForm && !bar.closeGuard }
    }
    Item {
        id: statusZone
        readonly property real grow: bar.collapsedH * (bar.circleScale - 1) / 2
        x: statusPill.unhoveredX - grow
        y: bar.topGap
        width: bar.collapsedH + bar.circlePush + 2 * grow
        height: bar.collapsedH + bar.circleDrop + grow
        HoverHandler { id: statusHover; enabled: statusPill.interactive && !statusPill.lent && !bar.morphWanted }
    }
    Item {
        id: artZone
        readonly property real grow: bar.collapsedH * (bar.circleScale - 1) / 2
        x: artPill.unhoveredX - bar.circlePush - grow
        y: bar.topGap
        width: bar.collapsedH + bar.circlePush + 2 * grow
        height: bar.collapsedH + bar.circleDrop + grow
        HoverHandler { id: artHover; enabled: artPill.interactive && !artPill.lent && !bar.morphWanted }
    }

    Item {
        id: notch
        anchors.top: parent.top
        // continuous: closes to 0 as it goes flush (notch or game bar). No Behavior here —
        // flushT is already animating, so one would just chase a per-frame target and stall.
        // + the stage drop (scaled out in notch mode, where the fill must stay flush) + the
        // from-circle transform, all folded into bar.stageTop / bar.stageX.
        anchors.topMargin: bar.stageTop
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: bar.stageX

        // Game Mode: ALWAYS a full-width bar (osd/notif show centred inside it; morph
        // panels float below via morphHost, neither one resizes the bar horizontally).
        width: bar.barForm ? (modelData?.width ?? bar.expandedW)
             : bar.islandMorph ? bar.morphW
             : (bar.notifWanted || bar.osdWanted) ? transientHost.contentW
             : bar.expanded ? bar.expandedW : bar.collapsedW + (bar.presenting ? bar.presentGrowW : 0)
        // Game Mode height: ALWAYS gameBarH, the bar never grows. A tall transient (a
        // notification) overflows DOWNWARD as a rounded-bottom projection (transientHost)
        // instead of stretching the whole bar. Normal mode: the island sizes to content.
        height: bar.barForm ? bar.gameBarH
              : bar.islandMorph ? morphHost.contentHeight
              : (bar.notifWanted || bar.osdWanted) ? transientHost.contentH
              : bar.expanded ? bar.expandedH : bar.collapsedH + (bar.presenting ? bar.presentGrowH : 0)
        // Corner radius, DERIVED from the live (already-animated) height instead of stepped on
        // state. Stepping it snapped the corners to the collapsed radius the INSTANT you hovered
        // off (or closed a panel) while the island was still at full height, so they flashed
        // sharp for a beat until the shrink caught up. As a pure function of the current height
        // they're always right for the size the island actually is, at every frame of the
        // animation. Interpolates rIsland→rIslandOpen across the collapse↔expand range and caps
        // there, so tall morph/notification surfaces still round fully. Clamped to half the box
        // so the arcs always fit. Both the island Rectangle and the notch Shape read this, so
        // neither shape can drift from the other.
        // Ramps from the collapsed pill's radius to the open card's, then holds. The ramp has
        // to be height-derived (not a flat per-state value) or the corners desync from the size
        // mid-morph and visibly pop. But it saturates as soon as the surface is TALL ENOUGH to
        // draw the open radius — 2*rIslandOpen — not at the expanded island's height. Ramping
        // all the way to expandedH meant every surface shorter than that got short-changed:
        // the power menu sat at 30.4 and the OSD at 21.4 while the launcher/CC/pickers were 31.
        // Now everything from ~62px up is exactly rIslandOpen, and the only surfaces below it
        // are ones physically too short to fit that corner (height/2 caps them).
        readonly property real radSat: 2 * Theme.rIslandOpen
        readonly property real rad: bar.barForm ? 0
              : Math.min(width / 2, height / 2,
                    Theme.rIsland + (Theme.rIslandOpen - Theme.rIsland)
                      * Math.max(0, Math.min(1, (height - bar.collapsedH)
                                                / Math.max(1, radSat - bar.collapsedH))))

        Behavior on width  { enabled: bar.morphAnim; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
        // Width and height animate on the SAME always-on Behavior so a morph is uniform (both
        // axes together, never one then the other). The island height is the ONE spring for
        // content changes too: content resizes instantly, contentHeight steps, this springs
        // to it, and the root's clip reveals the content as the island grows (patterns.md #48).
        // The one exception: while a list inside the control center folds on ITS spring
        // (`controlCenter.folding`) this stands aside and tracks the content frame by frame,
        // so that fold is still the only spring and the island moves in lockstep with it.
        Behavior on height { enabled: bar.morphAnim && !controlCenter.folding; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

        // drop-in entrance
        opacity: 0
        transform: Translate { id: dropT; y: -22 }
        Component.onCompleted: dropAnim.start()
        ParallelAnimation {
            id: dropAnim
            NumberAnimation { target: notch; property: "opacity"; from: 0; to: 1; duration: Theme.dur(Theme.dEnter); easing.type: Easing.OutCubic }
            NumberAnimation { target: dropT; property: "y"; from: -22; to: 0; duration: Theme.dur(Theme.dEnter); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
        }

        // THE fill — one shape for every form. Island (rounded top + gap above), notch
        // (flush, square-ish top flaring out at the corners), and the game bar all come out
        // of the same outline, interpolated by bar.notchT / bar.barT. There's no second
        // surface to swap to, so switching modes can't pop: the corners un-round, the flares
        // grow, and the top margin closes on one clock.
        //
        // In notch mode it overshoots the top edge a few px (`over`) so it sits TRULY flush,
        // with no sliver of desktop above it — that overshoot scales to 0 as it becomes the
        // floating island, which needs its gap back.
        Shape {
            id: notchFill
            readonly property real over: 4 * bar.notchT
            anchors.top: parent.top
            anchors.topMargin: -over
            anchors.horizontalCenter: parent.horizontalCenter
            width: notch.width + 2 * bar.notchFlareEff
            height: notch.height + over
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
            layer.enabled: Theme.shadows
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadow
                shadowBlur: Theme.shadowBlur
                shadowVerticalOffset: Theme.shadowY
                blurMax: Theme.shadowBlurMax
                autoPaddingEnabled: true
            }
            ShapePath {
                fillColor: Theme.base   // follows scheme polarity, same as the island body
                // hairline on the floating island only: flush against the screen edge it'd
                // read as a 1px strip holding the bar off the top. Fades out as it goes flush.
                strokeColor: Theme.hairline
                strokeWidth: (1 - bar.flushT)
                PathSvg {
                    path: bar.notchPath(notch.width, notch.height + notchFill.over,
                                        bar.notchTopR, bar.notchBR, bar.notchFlareEff)
                }
            }
        }

        // pin toggle: a press on any NON-interactive part of the island toggles pin.
        // Sits BELOW the content (declared before barRow), so the real buttons (cc pill,
        // media controls) grab their own clicks and only empty areas reach this. Replaces
        // a notch-wide TapHandler that fired even on the buttons.
        MouseArea {
            id: pinArea
            anchors.fill: parent
            enabled: !bar.morphWanted && !bar.notifWanted && !bar.osdWanted && !bar.barForm
            onClicked: bar.pinned = !bar.pinned
        }

        // bar content (media | clock): fades out as the island morphs
        RowLayout {
            id: barRow
            anchors.fill: parent
            // extra breathing room inside the EXPANDED island (7px on every side, on top of
            // the base s3 side inset). Animates via `pad` so the content eases inward as the
            // island opens instead of the margins jumping.
            property real pad: (bar.expanded && !bar.barForm) ? Config.islandPadding : 0
            Behavior on pad { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
            anchors.leftMargin: Theme.s3 + pad
            anchors.rightMargin: Theme.s3 + pad
            anchors.topMargin: pad
            anchors.bottomMargin: pad
            spacing: 0
            // hidden when an OSD/notification takes the bar, or when a panel morphs the
            // island in place (normal mode). In Game Mode the panels float BELOW, so the
            // bar cluster STAYS visible behind them.
            readonly property bool yielded: bar.osdWanted || bar.notifWanted || (bar.islandMorph && !bar.barForm)
            opacity: yielded ? 0 : 1
            enabled: !yielded
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }

            // game-bar spacers: fill ONLY in bar form, centring the clock cluster
            Item { Layout.fillWidth: bar.barForm }

            // CENTER: clock. Fills the middle (island); in bar form it's natural-width so
            // the outer fill-spacers centre the cluster and the inner gaps spread it out.
            Item {
                id: clock
                Layout.fillWidth: !bar.barForm
                Layout.preferredWidth: bar.barForm ? timeRow.width : 0
                Layout.fillHeight: true

                // subtle "button" affordance behind the time/date: a faint fill shows on
                // hover so the clock reads as pressable; pressing it morphs the island into
                // the calendar. Only active in the clock's full form (expanded island or game
                // bar); collapsed, clicks fall through to the pin toggle.
                Rectangle {
                    id: clockBtn
                    readonly property real sf: (bar.expanded && !bar.barForm) ? (Theme.fsClockBig / Theme.fsClock) : 1
                    // The clock is the ONLY element: it stays on the island centre in every state.
                    // Pure binding, NO Behavior on x (it would chase a target that moves every
                    // frame while the island springs). Time/date centre on THIS box (below) so the
                    // big-time scale stays in.
                    //
                    // Written against barRow (NOT the clock item) on purpose. The RowLayout hands
                    // `clock` INTEGER x/width, so while the spring settles its bounce arrives as 1px
                    // steps — that was the clock snapping sideways at the end of a collapse. Here the
                    // absolute position works out to barRow.width/2 - width/2: the clock.x terms
                    // CANCEL, leaving only continuous values (barRow's fractional width and the eased
                    // box width), so the settle is smooth.
                    x: bar.barForm ? (clock.width - width) / 2
                                   : barRow.width / 2 - clock.x - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: (bar.expanded && !bar.barForm) ? 2 : 0
                    width: Math.max(timeRow.width * sf, (bar.expanded && !bar.barForm) ? dateStrip.width : 0) + Theme.s4
                    height: (bar.expanded && !bar.barForm) ? 84 : 34
                    radius: Theme.rMd
                    visible: bar.expanded || bar.barForm
                    color: clockMa.containsMouse ? Theme.fillLow : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                    Behavior on width { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                }

                Row {
                    id: timeRow
                    // lift the time when expanded to make room for the date below; animate
                    // the numeric offset (not the font size) so it stays smooth.
                    property real shift: (bar.expanded && !bar.barForm) ? -22 : 0
                    Behavior on shift { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                    // centred on the clock button (which slides right on expand), so it rides
                    // along smoothly as the box moves into place
                    x: clockBtn.x + (clockBtn.width - width) / 2
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: shift
                    spacing: dotWrap.act ? Theme.s2 : 0
                    Behavior on spacing { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

                    // mini visualizer: animates in while music plays (collapsed)
                    Item {
                        id: dotWrap
                        readonly property bool act: Config.clockViz && bar.playing && !bar.expanded && !bar.barForm
                        anchors.verticalCenter: parent.verticalCenter
                        width: act ? viz.width : 0
                        height: 11
                        opacity: act ? 1 : 0
                        scale: act ? 1 : 0.3
                        transformOrigin: Item.Center
                        clip: true
                        Behavior on width { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                        Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                        Behavior on scale { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

                        Row {
                            id: viz
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            height: 11
                            spacing: 1.6
                            Repeater {
                                model: 4
                                Rectangle {
                                    required property int index
                                    width: 2.2; radius: 1.1
                                    anchors.bottom: parent.bottom
                                    color: Theme.accent
                                    height: 3
                                    SequentialAnimation on height {
                                        running: dotWrap.act
                                        loops: Animation.Infinite
                                        NumberAnimation { from: 3; to: 11; duration: 400 + index * 120; easing.type: Easing.InOutSine }
                                        NumberAnimation { from: 11; to: 3; duration: 400 + index * 120; easing.type: Easing.InOutSine }
                                    }
                                }
                            }
                        }
                    }

                    // Time. Sits DIRECTLY in the Row (not in a scale-tracking wrapper) on purpose:
                    // an item's width ignores its `scale` transform, so timeRow.width stays CONSTANT
                    // while the time scales up. clockBtn.width keys off it (times the step `sf`), so
                    // the button has one fixed target its Behavior can animate to cleanly. Wrapping
                    // this to report the animating scaled width made timeRow.width change every
                    // frame, so clockBtn's width Behavior chased a moving target and the whole clock
                    // stalled/stuttered on hover — same trap as a Behavior on x. Don't reintroduce it.
                    // The time, drawn per digit so the digits can ROLL — iPhone-lock-screen
                    // style: when a digit changes, the old glyph slides up and fades out while
                    // the new one rises into its place fading in, masked to the line box. Only
                    // the digits that actually change move (onChChanged fires per cell); the
                    // rest hold perfectly still.
                    //
                    // Cells take each character's PROPORTIONAL advance (no tabular figures —
                    // tnum gave "1" a full digit slot and the time read gap-toothed). Widths
                    // change only AT the tick, a discrete step identical to what the single
                    // Text used to do, and clockBtn's width Behavior smooths it; during the
                    // roll itself nothing resizes, so there's still no per-frame churn.
                    Row {
                        id: timeText
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0
                        transformOrigin: Item.Center
                        scale: (bar.expanded && !bar.barForm) ? (Theme.fsClockBig / Theme.fsClock) : bar.presenting ? 1.06 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

                        readonly property string timeStr: Qt.formatDateTime(sysclock.date, (Config.clock24h ? "HH:mm" : "h:mm") + (Config.clockSeconds ? ":ss" : "") + (Config.clock24h ? "" : " AP"))
                        SystemClock { id: sysclock; precision: Config.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes }

                        FontMetrics {
                            id: clockFm
                            font.family: Theme.fontDisplay
                            font.pixelSize: Theme.fsClock
                            font.weight: Theme.wSemiBold
                        }

                        Repeater {
                            model: timeText.timeStr.length
                            delegate: Item {
                                id: cell
                                required property int index
                                readonly property string ch: timeText.timeStr.charAt(cell.index)

                                width: chM.advanceWidth
                                height: clockFm.height
                                clip: true                        // the mask that sells the roll

                                TextMetrics {
                                    id: chM
                                    font.family: Theme.fontDisplay
                                    font.pixelSize: Theme.fsClock
                                    font.weight: Theme.wSemiBold
                                    text: cell.ch
                                }

                                // what's on screen; lags ch by one roll
                                property string shown: ""
                                property bool ready: false
                                Component.onCompleted: { shown = ch; ready = true; }
                                onChChanged: {
                                    if (!cell.ready || cell.shown === cell.ch) return;
                                    outT.text = cell.shown;
                                    cell.shown = cell.ch;
                                    roll.restart();
                                }

                                component ClockGlyph: Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    font.family: Theme.fontDisplay
                                    font.pixelSize: Theme.fsClock
                                    font.weight: Theme.wSemiBold
                                    color: Theme.inkPrimary
                                    renderType: Text.QtRendering
                                }

                                ClockGlyph { id: curT; text: cell.shown; y: 0 }
                                ClockGlyph { id: outT; opacity: 0 }

                                ParallelAnimation {
                                    id: roll
                                    // incoming: rises from below into place
                                    NumberAnimation { target: curT; property: "y"; from: cell.height * 0.6; to: 0; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
                                    NumberAnimation { target: curT; property: "opacity"; from: 0; to: 1; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
                                    // outgoing: keeps travelling up and out
                                    NumberAnimation { target: outT; property: "y"; from: 0; to: -cell.height * 0.6; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
                                    NumberAnimation { target: outT; property: "opacity"; from: 1; to: 0; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
                                }
                            }
                        }
                    }
                }

                // Date carousel: a flat strip of day cards with TODAY the selected centre card
                // (full opacity, accent number, light-grey weekday) and the neighbours fading out
                // by opacity toward the edges. Evenly spaced — no dial curvature/foreshortening;
                // the cos-falloff is kept ONLY to drive that edge opacity. Rides the clock box as
                // it slides right; expanded island only.
                Row {
                    id: dateStrip
                    readonly property int cellH: 34
                    x: clockBtn.x + (clockBtn.width - width) / 2
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 23          // clear of the lifted time above
                    visible: Config.dateKnobShow
                    opacity: (bar.expanded && !bar.barForm) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }

                    Item {
                        id: knob
                        readonly property int cells: Config.dateKnobDays   // odd, so today sits centred
                        readonly property real dTheta: Config.dateKnobAngle * Math.PI / 180  // drives the opacity falloff only
                        readonly property int cellW: 30
                        width: cells * cellW
                        height: dateStrip.cellH

                        Repeater {
                            model: knob.cells
                            Item {
                                id: dayCell
                                required property int index
                                readonly property int off: index - Math.floor(knob.cells / 2)
                                readonly property real ct: Math.cos(dayCell.off * knob.dTheta)
                                readonly property var d: {
                                    var b = new Date(sysclock.date);
                                    b.setDate(b.getDate() + dayCell.off);
                                    return b;
                                }
                                readonly property bool today: dayCell.off === 0
                                readonly property bool weekend: { var g = d.getDay(); return g === 0 || g === 6; }

                                width: knob.cellW
                                height: knob.height
                                // even spacing, today dead centre (no dial bunching)
                                x: knob.width / 2 - width / 2 + dayCell.off * knob.cellW
                                visible: ct > 0.03
                                // keep JUST the opacity falloff toward the edges (the good bit)
                                opacity: Math.pow(Math.max(0, ct), 1.6)

                                // the SELECTED card: a subtle fill behind today only
                                Rectangle {
                                    visible: dayCell.today
                                    anchors.centerIn: parent
                                    width: parent.width + 4
                                    height: dateStrip.cellH
                                    radius: Theme.rSm
                                    color: Theme.fillLow
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 1

                                    StyledText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        // today spells the weekday (MON); the rest are initials
                                        text: dayCell.today ? Qt.formatDateTime(dayCell.d, "ddd").toUpperCase()
                                                            : Qt.formatDateTime(dayCell.d, "ddd").charAt(0)
                                        font.pixelSize: Theme.fsCaption
                                        font.weight: dayCell.today ? Theme.wMedium : Theme.wRegular
                                        // today's weekday: a light grey, brighter than the neighbours' initials
                                        color: dayCell.today ? Theme.alpha(Theme.foreground, 0.78)
                                             : dayCell.weekend ? Theme.alpha(Theme.red, 0.75)
                                             : Theme.inkFaint
                                    }
                                    StyledText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: Qt.formatDateTime(dayCell.d, "d")
                                        font.family: Theme.fontDisplay
                                        font.pixelSize: dayCell.today ? Theme.fsTitle : Theme.fsLabel
                                        font.weight: dayCell.today ? Theme.wSemiBold : Theme.wRegular
                                        color: dayCell.today ? Theme.accent
                                             : dayCell.weekend ? Theme.alpha(Theme.red, 0.85)
                                             : Theme.inkDim
                                    }
                                }
                            }
                        }
                    }
                }

                // press target: opens the calendar. Sits on top of the text so it grabs the
                // click instead of the pin-toggle behind the island.
                MouseArea {
                    id: clockMa
                    anchors.fill: clockBtn
                    enabled: bar.expanded || bar.barForm
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: GlobalState.toggleCalendar()
                }
            }

            // game-bar trailing spacer (fills only in bar form): pairs with the leading
            // one to keep the clock cluster centred on the full-width bar.
            Item { Layout.fillWidth: bar.barForm }
        }

    }

    // status circle (battery ring + Wi-Fi): a satellite the height of the collapsed pill,
    // hung off the island's right edge. It reads the notch's live width, so every morph
    // pushes it along on the same spring, and it shares the drop-in entrance. The game bar
    // is full width, so there is no edge to hang off; it fades out with the morph.
    StatusPill {
        id: statusPill
        size: bar.collapsedH
        // hung off the island's right edge, but never left of its RESTING spot: a surface
        // that grows from the left must push it, never drag it
        readonly property real restX: bar.width / 2 - bar.pillShift + bar.collapsedW / 2 + bar.topGap
        readonly property real unhoveredX: Math.max(restX, notch.x + notch.width + bar.notchFlareEff + bar.topGap) + bar.presentPush * bar.presentT
        x: unhoveredX + bar.circlePush * hoverT
        zoneHovered: statusHover.hovered
        y: bar.topGap + bar.circleDrop * hoverT
        grow: bar.circleScale
        lent: ccSat.live
        lentT: ccSat.c
        opening: bar.ccFromPill
        z: lent ? 2 : 0     // glyphs cross-fade ON TOP of the fill growing out of it
        interactive: !bar.barForm
        opacity: notch.opacity * (1 - bar.barT) * (Config.statusPill ? 1 : 0)
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        transform: Translate { y: dropT.y }
    }

    // art circle: the status circle's twin on the left, up while a music player is open
    ArtPill {
        id: artPill
        size: bar.collapsedH
        readonly property real restX: bar.width / 2 - bar.pillShift - bar.collapsedW / 2 - bar.topGap - width
        readonly property real unhoveredX: Math.min(restX, notch.x - bar.notchFlareEff - bar.topGap - width) - bar.presentPush * bar.presentT
        x: unhoveredX - bar.circlePush * hoverT
        zoneHovered: artHover.hovered
        y: bar.topGap + bar.circleDrop * hoverT
        grow: bar.circleScale
        interactive: !bar.barForm
        lent: mediaSat.live
        lentT: mediaSat.c
        opening: bar.mediaFromPill
        z: lent ? 2 : 0
        opacity: notch.opacity * (1 - bar.barT) * Math.max(0, Math.min(1, bar.artT))
        visible: opacity > 0.01
        transform: Translate { y: dropT.y }
    }

    // transient host: OSD + notification + mode indicator. NORMAL mode: coincides with
    // the notch (rides notch.fill), so the island morphs to the content like before. GAME
    // mode: the notch stays a gameBarH bar, so this sits centred IN it; if the content is
    // TALLER than the bar it does NOT stretch the bar, it overflows DOWNWARD as a
    // rounded-bottom projection (squared top so it merges into the bar, like a tab
    // hanging off it). Single instances; the notch references these ids for normal sizing.
    Item {
        id: transientHost
        readonly property bool shown: bar.notifWanted || bar.osdWanted
        readonly property int contentH: bar.notifWanted ? (notifIsland.implicitHeight + Theme.s3 * 2)
              : bar.osdWanted ? (osdIsland.implicitHeight + Theme.s3 * 2)
              : bar.collapsedH
        readonly property int contentW: bar.notifWanted ? bar.notifW
              : bar.osdWanted ? (OsdState.kind === "mode" ? (osdIsland.modeWidth + Theme.s5 * 2) : bar.osdW)
              : bar.collapsedW
        // game mode + content taller than the bar → it projects below the bar
        readonly property bool overflow: bar.barForm && contentH > bar.gameBarH

        anchors.top: parent.top
        anchors.topMargin: bar.stageTop   // rides the same clocks as the notch
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: bar.stageX
        // NORMAL mode: clip the (fixed-width, centred) content to the notch while it grows
        // from collapsed → full, or the icon/%/label hang outside the pill onto the
        // wallpaper for a frame before the background catches up. The content gets revealed
        // as the pill expands instead. GAME mode: don't clip, 'cause the bar's already full
        // width (no overflow) and clipping would cut the projection's drop shadow.
        clip: !bar.barForm
        // game: own footprint, growing DOWN past the bar for tall content. normal: ride
        // the notch exactly (the island is the animated surface; this just follows it).
        width: bar.barForm ? contentW : notch.width
        height: bar.barForm ? Math.max(bar.gameBarH, contentH) : notch.height
        Behavior on width  { enabled: bar.barForm; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
        Behavior on height { enabled: bar.barForm; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

        // the projection background: drawn ONLY in Game Mode when the content overflows
        // the bar. Squared top (flush with / merging into the bar), rounded bottom so it
        // reads as a tab projecting out of the bar.
        Rectangle {
            id: projFill
            anchors.fill: parent
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: Theme.rIslandOpen
            bottomRightRadius: Theme.rIslandOpen
            color: Theme.base   // island body: solid black, like the notch fill
            antialiasing: true
            visible: transientHost.overflow
            opacity: transientHost.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
            layer.enabled: Theme.shadows
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadow
                shadowBlur: Theme.shadowBlur
                shadowVerticalOffset: Theme.shadowY
                blurMax: Theme.shadowBlurMax
                autoPaddingEnabled: true
            }
        }

        NotificationIsland {
            id: notifIsland
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: bar.notifW - Theme.s3 * 2
            notif: Notifications.showing
            opacity: bar.notifWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        OsdIsland {
            id: osdIsland
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: OsdState.kind === "mode" ? osdIsland.modeWidth : (bar.osdW - Theme.s3 * 2)
            opacity: bar.osdWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
    }

    // morph panels host (launcher / control center / pickers / settings / power /
    // polkit). NORMAL mode: it coincides with the notch exactly (same centre, width,
    // height, top margin), so a panel reads as the island morphing IN PLACE: the
    // notch.fill is its background and morphFill stays hidden. GAME mode: the notch
    // stays a top bar, so this detaches and FLOATS just below it with its own fill +
    // shadow. Single instances live here (no per-mode duplication of stateful panels).
    Item {
        id: morphHost
        // game bar: floats below it. notch: flush. island: its gap. Written as ONE continuous
        // expression off barT/flushT rather than branches + a Behavior, so it never steps.
        x: bar.width / 2 + bar.stageX - width / 2
        y: (notch.height + Theme.s2) * bar.barT + bar.stageTop

        // the height the open panel wants: single source of truth (the notch reads this
        // too when it morphs the panel in place).
        readonly property int contentHeight: bar.polkitWanted ? (polkitContent.implicitHeight + Theme.s4 * 2)
              : bar.launcherWanted ? (launcher.implicitHeight + Theme.s4 * 2)
              : (bar.ccWanted && !bar.ccFromPill) ? (controlCenter.implicitHeight + Theme.s4 * 2)
              : bar.wallpaperWanted ? (wallpaperContent.implicitHeight + Theme.s4 * 2)
              : bar.themeWanted ? (themeContent.implicitHeight + Theme.s4 * 2)
              : bar.logoutWanted ? (logoutContent.implicitHeight + Theme.s4 * 2)
              : bar.calendarWanted ? (calendarContent.implicitHeight + Theme.s4 * 2)
              : (bar.mediaWanted && !bar.mediaFromPill) ? (mediaContent.implicitHeight + Theme.s4 * 2)
              : 0

        // game: own footprint (floats below). normal: ride the notch exactly (seamless
        // in-place morph, the notch is the animated surface and this just follows it).
        width: bar.barForm ? bar.morphW : notch.width
        height: bar.barForm ? contentHeight : notch.height
        Behavior on width  { enabled: bar.barForm; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
        Behavior on height { enabled: bar.barForm; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

        // own background: drawn ONLY in Game Mode (when floating below the bar). In
        // normal mode the notch.fill behind us is the panel's background.
        Rectangle {
            id: morphFill
            anchors.fill: parent
            radius: Theme.rIslandOpen
            color: Theme.base   // island body: solid black, like the notch fill
            border.width: 1
            border.color: Theme.hairline
            antialiasing: true
            visible: bar.barForm
            opacity: bar.morphWanted ? 1 : 0
            Behavior on opacity { enabled: bar.barForm; NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
            layer.enabled: Theme.shadows
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadow
                shadowBlur: Theme.shadowBlur
                shadowVerticalOffset: Theme.shadowY
                blurMax: Theme.shadowBlurMax
                autoPaddingEnabled: true
            }
        }

        // swallow clicks inside the panel (so they don't reach the click-outside backdrop)
        MouseArea {
            anchors.fill: parent
            enabled: bar.morphWanted
        }

        LauncherContent {
            id: launcher
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.launcherWanted
            opacity: bar.launcherWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        ControlCenterContent {
            id: controlCenter
            // lives in the status circle's host while that host is live (open, or still
            // closing), in the island's host otherwise; laid out at final size under its
            // clip, revealed as the container grows, fading in over the second half (#31)
            parent: ccSat.live ? ccSat : morphHost
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.ccWanted
            opacity: ccSat.live ? ccSat.contentOpacity : bar.ccWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { enabled: !ccSat.live; NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        WallpaperContent {
            id: wallpaperContent
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.wallpaperWanted
            opacity: bar.wallpaperWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        ThemeContent {
            id: themeContent
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.themeWanted
            opacity: bar.themeWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        LogoutContent {
            id: logoutContent
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.logoutWanted
            opacity: bar.logoutWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        PolkitContent {
            id: polkitContent
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.polkitWanted
            opacity: bar.polkitWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        CalendarContent {
            id: calendarContent
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.calendarWanted
            opacity: bar.calendarWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        MediaContent {
            id: mediaContent
            parent: mediaSat.live ? mediaSat : morphHost
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.mediaWanted
            opacity: mediaSat.live ? mediaSat.contentOpacity : bar.mediaWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { enabled: !mediaSat.live; NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
    }

    // ── the circles' panel hosts ──
    component SatHost: Item {
        id: sat
        property Item pill: null
        property string side: "right"     // "right": top-LEFT on the circle's top-left; "left": top-RIGHT on its top-right
        property bool wanted: false
        property int panelW: 400
        property Item content: null
        property bool folding: false      // a list inside folds on its own spring: the height spring stands aside
        property bool live: false         // in flight or open
        property bool open: false         // the open spring has landed; content-driven height changes now spring
        property real t: 0
        Behavior on t { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier
                                          onRunningChanged: if (!running) { if (sat.t < 0.001 && !sat.wanted) sat.live = false; else if (sat.wanted) sat.open = true; } } }
        // geometry clock: the raw spring overshoots past 1 on the open (the panel lands with
        // a bounce, like every surface) but must NOT undershoot below 0 on the close: that
        // 1.5% is scaled by the whole panel, ~8px, and the container shrank smaller than the
        // disc it hands back to. Clamped at the circle, so the settle is exact.
        readonly property real c: Math.max(0, t)
        // origin: the circle's live rect (bar coords). Its hover is frozen while lent and the
        // island does not move for this morph, so the rect holds still for the whole transform.
        readonly property real os: pill ? pill.size * pill.scale : 37
        readonly property real ox: pill ? pill.x + pill.width / 2 : 0
        readonly property real oy: pill ? pill.y + pill.height / 2 - os / 2 : 0
        // the panel's rect, sampled at the open and HELD through the close
        property real targetW: 400
        property real targetH: 0
        readonly property real contentH: content ? content.implicitHeight + Theme.s4 * 2 : 0
        onContentHChanged: if (wanted && contentH > 0) targetH = contentH
        // the ONE spring for content-driven resizes while open (a sheet opening, back): the
        // content resizes instantly, this springs to it, the content's clip reveals it (#48)
        Behavior on targetH { enabled: sat.open && !sat.folding; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
        readonly property real panelX: Math.max(bar.topGap, Math.min(side === "left" ? ox + os / 2 - targetW : ox - os / 2, bar.width - targetW - bar.topGap))
        readonly property real contentOpacity: live ? Math.max(0, Math.min(1, (t - 0.35) / 0.5)) : (wanted ? 1 : 0)
        onWantedChanged: {
            if (wanted) { open = false; targetW = panelW; targetH = contentH; live = true; t = 1; }
            else { open = false; t = 0; }
        }
        visible: live
        x: bar.lerp(ox - os / 2, panelX, c)
        y: oy
        width: Math.max(10, bar.lerp(os, targetW, c))
        height: Math.max(10, bar.lerp(os, targetH, c))
        Rectangle {
            anchors.fill: parent
            // a disc at t=0, the open card's corner once tall enough
            radius: Math.min(width / 2, height / 2, Theme.rIslandOpen)
            color: Theme.base
            border.width: 1
            border.color: Theme.hairline
            antialiasing: true
            layer.enabled: Theme.shadows
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadow
                shadowBlur: Theme.shadowBlur
                shadowVerticalOffset: Theme.shadowY
                blurMax: Theme.shadowBlurMax
                autoPaddingEnabled: true
            }
        }
        MouseArea { anchors.fill: parent; enabled: sat.live }   // swallow clicks inside the panel
    }
    SatHost { id: ccSat;    pill: statusPill; side: "right"; wanted: bar.ccFromPill;    panelW: bar.launcherW; content: controlCenter; folding: controlCenter.folding }
    SatHost { id: mediaSat; pill: artPill;    side: "left";  wanted: bar.mediaFromPill; panelW: bar.mediaW;    content: mediaContent }

}
