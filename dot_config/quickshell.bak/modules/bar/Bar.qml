import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
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
import "../settings"
import "../polkit"
import "../calendar"

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
    exclusiveZone: barForm ? gameBarH : Math.max(0, topGap * 2 + collapsedH - gapsOut)
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
    }

    property bool pinned: false
    readonly property bool expanded: hover.hovered || pinned
    readonly property bool playing: Media.player?.isPlaying ?? false

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
    readonly property bool settingsWanted: GlobalState.settingsOpen && onFocusedMon && !polkitWanted
    readonly property bool calendarWanted: GlobalState.calendarOpen && onFocusedMon && !polkitWanted
    // any of these panels morphs the island; the window's full-height already, so this
    // just drives keyboard focus + the click-outside backdrop + the input mask.
    readonly property bool morphWanted: polkitWanted || launcherWanted || ccWanted || wallpaperWanted || themeWanted || logoutWanted || settingsWanted || calendarWanted
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
    readonly property int gameBarH: 50
    readonly property int gameClusterGap: 180   // gap between each card and the clock in bar form

    readonly property int topGap: Theme.s2        // gap above the island (and below it too, via exclusiveZone)
    readonly property int gapsOut: 8             // must match Hyprland general:gaps_out (top); subtract it or it stacks
    readonly property int collapsedW: 150
    readonly property int collapsedH: Math.max(34, Config.barHeight + 4)
    readonly property int expandedW: 560
    readonly property int expandedH: 92
    readonly property int launcherW: 560
    readonly property int calendarW: 360                       // the calendar's a compact morph
    readonly property int morphW: calendarWanted ? calendarW : launcherW
    readonly property int notifW: 480
    readonly property int osdW: 300

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
            GlobalState.settingsOpen = false;
            GlobalState.calendarOpen = false;
        }
    }

    Item {
        id: notch
        anchors.top: parent.top
        anchors.topMargin: bar.barForm ? 0 : bar.topGap   // bar form sits flush on the top edge
        Behavior on anchors.topMargin { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
        anchors.horizontalCenter: parent.horizontalCenter

        // Game Mode: ALWAYS a full-width bar (osd/notif show centred inside it; morph
        // panels float below via morphHost, neither one resizes the bar horizontally).
        width: bar.barForm ? (modelData?.width ?? bar.expandedW)
             : bar.morphWanted ? bar.morphW
             : (bar.notifWanted || bar.osdWanted) ? transientHost.contentW
             : bar.expanded ? bar.expandedW : bar.collapsedW
        // Game Mode height: ALWAYS gameBarH, the bar never grows. A tall transient (a
        // notification) overflows DOWNWARD as a rounded-bottom projection (transientHost)
        // instead of stretching the whole bar. Normal mode: the island sizes to content.
        height: bar.barForm ? bar.gameBarH
              : bar.morphWanted ? morphHost.contentHeight
              : (bar.notifWanted || bar.osdWanted) ? transientHost.contentH
              : bar.expanded ? bar.expandedH : bar.collapsedH
        readonly property int rad: bar.barForm ? 0
              : (bar.morphWanted || bar.notifWanted || bar.osdWanted || bar.expanded) ? Theme.rIslandOpen : Theme.rIsland

        Behavior on width  { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
        Behavior on height { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

        // drop-in entrance
        opacity: 0
        transform: Translate { id: dropT; y: -22 }
        Component.onCompleted: dropAnim.start()
        ParallelAnimation {
            id: dropAnim
            NumberAnimation { target: notch; property: "opacity"; from: 0; to: 1; duration: Theme.dur(Theme.dEnter); easing.type: Easing.OutCubic }
            NumberAnimation { target: dropT; property: "y"; from: -22; to: 0; duration: Theme.dur(Theme.dEnter); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
        }

        // floating island: solid background fill + hairline on all corners + shadow
        Rectangle {
            id: fill
            anchors.fill: parent
            radius: notch.rad
            color: Theme.background
            // no hairline in bar form: it'd read as a 1px strip holdin' the bar off the
            // top edge, and the bar wants to sit flush against the screen edge.
            border.width: bar.barForm ? 0 : 1
            border.color: Theme.hairline
            antialiasing: true
            Behavior on radius { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadow
                shadowBlur: Theme.shadowBlur
                shadowVerticalOffset: Theme.shadowY
                blurMax: Theme.shadowBlurMax
                autoPaddingEnabled: true
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

        // bar content (media | clock | cc): fades out as the island morphs
        RowLayout {
            id: barRow
            anchors.fill: parent
            anchors.leftMargin: Theme.s3
            anchors.rightMargin: Theme.s3
            spacing: 0
            // hidden when an OSD/notification takes the bar, or when a panel morphs the
            // island in place (normal mode). In Game Mode the panels float BELOW, so the
            // bar cluster STAYS visible behind them.
            readonly property bool yielded: bar.osdWanted || bar.notifWanted || (bar.morphWanted && !bar.barForm)
            opacity: yielded ? 0 : 1
            enabled: !yielded
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }

            // game-bar spacers: fill ONLY in bar form, centring the media|clock|cc cluster
            Item { Layout.fillWidth: bar.barForm }

            // LEFT: media (reveals on expand, or always in bar form)
            Item {
                id: leftZone
                property real zw: (bar.expanded || bar.barForm) ? 160 : 0
                Layout.preferredWidth: zw
                Layout.fillHeight: true
                clip: true
                opacity: (bar.expanded || bar.barForm) ? 1 : 0
                Behavior on zw { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }

                RowLayout {
                    id: mediaRow
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.s3
                    transform: Translate { id: mediaT; y: 0 }

                    // album art: rounded square, masked and crossfaded on track change
                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 36          // RowLayout sizes off Layout.*/implicit, not width
                        Layout.preferredHeight: 36
                        implicitWidth: 36; implicitHeight: 36

                        Rectangle {
                            id: artPlaceholder
                            anchors.fill: parent
                            radius: Theme.rMd
                            color: Theme.surfaceOverlay
                            opacity: artImg.ready ? 0 : 1     // crossfades with the art on change
                            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                            Icon {
                                anchors.centerIn: parent
                                name: "music"
                                color: Theme.accent
                            }
                        }
                        Image {
                            id: artImg
                            readonly property bool ready: status === Image.Ready && source.toString() !== ""
                            anchors.fill: parent
                            source: Media.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: false
                            layer.enabled: true
                        }
                        Rectangle {
                            id: artMask
                            anchors.fill: parent
                            radius: Theme.rMd
                            visible: false
                            layer.enabled: true
                        }
                        MultiEffect {
                            anchors.fill: parent
                            source: artImg
                            maskEnabled: true
                            maskSource: artMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            opacity: artImg.ready ? 1 : 0     // fade the new art in (was an abrupt pop)
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                        }
                    }

                    // title + artist
                    Column {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Row {
                            spacing: 0
                            Item {
                                id: eqWrap
                                // pin the EQ's bottom to the title's text baseline (its own
                                // baseline = its bottom) so the bars sit on the same line as
                                // the song name no matter the script (Latin descent vs CJK).
                                baselineOffset: height
                                anchors.baseline: titleText.baseline
                                height: 12
                                // width includes the trailing gap so the title slides in
                                // continuously (no snap) as this collapses on pause.
                                width: bar.playing ? eqRow.width + Theme.s2 : 0
                                clip: true
                                opacity: bar.playing ? 1 : 0
                                Behavior on width { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                                Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }

                                Row {
                                    id: eqRow
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 12                 // fixed baseline so bars don't bounce vertically
                                    spacing: 2
                                    Repeater {
                                        model: 4
                                        Rectangle {
                                            required property int index
                                            width: 2.6; radius: 1.3
                                            anchors.bottom: parent.bottom
                                            color: Theme.accent
                                            height: 3
                                            SequentialAnimation on height {
                                                running: bar.playing
                                                loops: Animation.Infinite
                                                NumberAnimation { from: 3; to: 12; duration: 420 + index * 130; easing.type: Easing.InOutSine }
                                                NumberAnimation { from: 12; to: 3; duration: 420 + index * 130; easing.type: Easing.InOutSine }
                                            }
                                        }
                                    }
                                }
                            }
                            StyledText {
                                id: titleText
                                anchors.verticalCenter: parent.verticalCenter
                                text: Media.player?.trackTitle ?? "Nothing playing"
                                font.weight: Theme.wMedium
                                font.pixelSize: Theme.fsLabel
                                color: Theme.inkPrimary
                                elide: Text.ElideRight
                                width: 104 - eqWrap.width
                            }
                        }
                        StyledText {
                            text: Media.player?.trackArtist ?? ""
                            font.pixelSize: Theme.fsCaption
                            color: Theme.inkDim
                            elide: Text.ElideRight
                            width: 104
                        }
                    }
                }

                // Scroll over the MEDIA (left side only) to switch tracks: down → next,
                // up → prev (switches songs, doesn't seek). Scoped to leftZone so scrolling
                // the clock does nothing. MouseArea.onWheel, 'cause WheelHandler doesn't get
                // wheel on this layer surface; NoButton so it never eats clicks.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: (wheel) => {
                        const dy = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y;
                        if (bar.expanded && dy !== 0) leftZone.switchTrack(dy < 0 ? -1 : 1);
                    }
                }

                property int slideDir: -1   // -1 = next (media enters from below), +1 = prev (from above)
                property bool scrollSwitch: false   // a scroll knows the direction; app-initiated changes don't
                function switchTrack(dir) {
                    const p = Media.player;
                    if (!p || mediaCooldown.running) return;
                    if (dir < 0 ? !p.canGoNext : !p.canGoPrevious) return;
                    leftZone.slideDir = dir;
                    leftZone.scrollSwitch = true;
                    if (dir < 0) p.next(); else p.previous();
                    mediaCooldown.restart();
                }
                Timer { id: mediaCooldown; interval: 300 }

                // Animate EVERY track change (scroll OR app-initiated): the whole media row
                // (art + title/artist) slides in from slideDir. NEXT enters from below (moves
                // up), PREV enters from above (moves down), opposite so they read distinctly.
                property string curTitle: Media.player?.trackTitle ?? ""
                onCurTitleChanged: {
                    // scroll → directional slide (we know next vs prev); app-initiated change
                    // → neutral crossfade, 'cause MPRIS can't report direction so don't fake one.
                    if (leftZone.scrollSwitch) mediaSlideIn.restart();
                    else mediaCrossfade.restart();
                    leftZone.scrollSwitch = false;
                }
                // SCROLL switch: directional slide. NEXT enters from below (moves up), PREV
                // from above (moves down). Starts partly visible so the direction reads.
                SequentialAnimation {
                    id: mediaSlideIn
                    readonly property int dist: 20
                    PropertyAction { target: mediaT; property: "y"; value: -leftZone.slideDir * mediaSlideIn.dist }
                    PropertyAction { target: mediaRow; property: "opacity"; value: 0.4 }
                    ParallelAnimation {
                        NumberAnimation { target: mediaT; property: "y"; to: 0; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
                        NumberAnimation { target: mediaRow; property: "opacity"; to: 1; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
                    }
                }
                // APP-initiated change: a plain crossfade, no slide so no direction's implied.
                SequentialAnimation {
                    id: mediaCrossfade
                    PropertyAction { target: mediaT; property: "y"; value: 0 }
                    PropertyAction { target: mediaRow; property: "opacity"; value: 0 }
                    NumberAnimation { target: mediaRow; property: "opacity"; to: 1; duration: Theme.dur(Theme.dBase); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
                }
            }

            // inner gap (bar form only): separates media from the clock so the cards sit
            // further out while the cluster stays centred (paired with the right one below).
            Item { Layout.preferredWidth: bar.barForm ? bar.gameClusterGap : 0 }

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
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: (bar.expanded && !bar.barForm) ? 2 : 0
                    width: Math.max(timeRow.width * sf, (bar.expanded && !bar.barForm) ? dateText.width : 0) + Theme.s4
                    height: (bar.expanded && !bar.barForm) ? 58 : 34
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
                    property real shift: (bar.expanded && !bar.barForm) ? -11 : 0
                    Behavior on shift { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: shift
                    spacing: dotWrap.act ? Theme.s2 : 0
                    Behavior on spacing { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

                    // mini visualizer: animates in while music plays (collapsed)
                    Item {
                        id: dotWrap
                        readonly property bool act: bar.playing && !bar.expanded && !bar.barForm
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

                    StyledText {
                        id: timeText
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(sysclock.date, "HH:mm")
                        font.family: Theme.fontDisplay
                        font.pixelSize: Theme.fsClock             // base; expand via smooth scale
                        font.weight: Theme.wSemiBold
                        font.letterSpacing: -0.5
                        font.features: { "tnum": 1 }
                        color: Theme.inkPrimary
                        // scale (not font.pixelSize) so growth's smooth and sub-pixel; QtRendering
                        // (distance field) scales crisp without re-rasterizing per integer size.
                        renderType: Text.QtRendering
                        transformOrigin: Item.Center
                        scale: (bar.expanded && !bar.barForm) ? (Theme.fsClockBig / Theme.fsClock) : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                        SystemClock { id: sysclock; precision: SystemClock.Minutes }
                    }
                }

                StyledText {
                    id: dateText
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 15          // fixed spot just below the centered time
                    text: Qt.formatDateTime(sysclock.date, "ddd, MMM d")
                    font.pixelSize: Theme.fsCaption
                    opacity: (bar.expanded && !bar.barForm) ? 1 : 0
                    color: Theme.inkDim
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
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

            // inner gap (bar form only): mirror of the left one, separating clock from cc.
            Item { Layout.preferredWidth: bar.barForm ? bar.gameClusterGap : 0 }

            // RIGHT: control-center pill (reveals on expand, or always in bar form)
            Item {
                id: rightZone
                property real zw: (bar.expanded || bar.barForm) ? 160 : 0
                Layout.preferredWidth: zw
                Layout.fillHeight: true
                clip: true
                opacity: (bar.expanded || bar.barForm) ? 1 : 0
                Behavior on zw { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }

                Rectangle {
                    id: cc
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 32
                    width: ccRow.implicitWidth + Theme.s3
                    radius: Theme.rMd
                    color: ccMa.containsMouse ? Theme.alpha(Theme.accent, 0.10) : Theme.fillLow
                    border.width: 1
                    border.color: ccMa.containsMouse ? Theme.accent : Theme.hairline
                    Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                    Behavior on border.color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }

                    Row {
                        id: ccRow
                        anchors.centerIn: parent
                        spacing: Theme.s2

                        WifiIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            active: Network.connected
                            strength: Network.connected ? (Network.isWifi ? Network.signalStrength : 1) : 0
                        }
                        BatteryIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: Battery.available
                            level: Battery.percentage / 100
                            low: Battery.low
                            charging: Battery.charging
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !Battery.available     // battery % now lives inside the icon; show volume only when there's no battery
                            text: `${Math.round(Audio.volume * 100)}%`
                            font.pixelSize: Theme.fsCaption
                            font.weight: Theme.wMedium
                            font.features: { "tnum": 1 }   // tabular, so the width won't twitch
                            color: Theme.inkDim
                        }
                    }

                    // a real MouseArea (not a TapHandler) so it grabs the press
                    // exclusively: clicks on the pill open the CC and do NOT fall
                    // through to the pin-toggle area behind the island.
                    MouseArea {
                        id: ccMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: GlobalState.toggleControlCenter()
                    }
                }
            }

            // game-bar trailing spacer (fills only in bar form): pairs with the leading
            // one to keep the media|clock|cc cluster centred on the full-width bar.
            Item { Layout.fillWidth: bar.barForm }
        }

        HoverHandler { id: hover; enabled: !bar.morphWanted && !bar.notifWanted && !bar.osdWanted && !bar.barForm }
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
        anchors.topMargin: bar.barForm ? 0 : bar.topGap
        anchors.horizontalCenter: parent.horizontalCenter
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
            color: Theme.background
            antialiasing: true
            visible: transientHost.overflow
            opacity: transientHost.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
            layer.enabled: true
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
        anchors.top: parent.top
        anchors.topMargin: bar.barForm ? (notch.height + Theme.s2) : bar.topGap
        anchors.horizontalCenter: parent.horizontalCenter
        Behavior on anchors.topMargin { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

        // the height the open panel wants: single source of truth (the notch reads this
        // too when it morphs the panel in place).
        readonly property int contentHeight: bar.polkitWanted ? (polkitContent.implicitHeight + Theme.s4 * 2)
              : bar.launcherWanted ? (launcher.implicitHeight + Theme.s4 * 2)
              : bar.ccWanted ? (controlCenter.implicitHeight + Theme.s4 * 2)
              : bar.wallpaperWanted ? (wallpaperContent.implicitHeight + Theme.s4 * 2)
              : bar.themeWanted ? (themeContent.implicitHeight + Theme.s4 * 2)
              : bar.logoutWanted ? (logoutContent.implicitHeight + Theme.s4 * 2)
              : bar.settingsWanted ? (settingsContent.implicitHeight + Theme.s4 * 2)
              : bar.calendarWanted ? (calendarContent.implicitHeight + Theme.s4 * 2)
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
            color: Theme.background
            border.width: 1
            border.color: Theme.hairline
            antialiasing: true
            visible: bar.barForm
            opacity: bar.morphWanted ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
            layer.enabled: true
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
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.ccWanted
            opacity: bar.ccWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
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
        SettingsContent {
            id: settingsContent
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.settingsWanted
            opacity: bar.settingsWanted ? 1 : 0
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
    }

    // While the launcher's open, hide the pointer everywhere (it's keyboard-driven).
    // NoButton so it doesn't steal clicks: the click-outside dismiss + result clicks
    // still work, this only overrides the cursor shape. Pointer comes back on close.
    MouseArea {
        anchors.fill: parent
        enabled: bar.launcherWanted
        visible: bar.launcherWanted
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.BlankCursor
    }
}
