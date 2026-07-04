import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// Control center guts, living inside the bar's island (see Bar.qml). Android-16 /
// Material-You quick settings: a 2-column grid of toggle tiles, thick sliders, media,
// notifications. Tap a tile to toggle; long-press to drill into that domain's sub-view
// (Wi-Fi / Bluetooth / Audio). Sub-views push/pop with a slide+fade and the island
// resizes between 'em. The back button's context-aware: sub-view → main → island.
Item {
    id: root

    property bool active: false
    implicitHeight: column.implicitHeight
    clip: true

    property string view: "main"          // which sub-view we're in: main | wifi | bluetooth | audio | display
    property var pskTarget: null
    readonly property var brightnessMon: Brightness.focused()
    readonly property int slide: Theme.s6   // how far the sub-views slide on push/pop


    function close() { GlobalState.controlCenterOpen = false; }
    function back() {
        if (view !== "main") { view = "main"; Network.setScanning(false); pskTarget = null; }
        else close();
    }

    function wifiClicked(net) {
        if (net.connected) { net.disconnect(); return; }
        if (net.known) { net.connect(); return; }
        pskTarget = net;
        Qt.callLater(() => pskField.forceActiveFocus());
    }

    onActiveChanged: {
        if (active) {
            view = "main";
            Display.refresh();
            Qt.callLater(() => keyCatcher.forceActiveFocus());
        } else {
            view = "main";
            pskTarget = null;
            Network.setScanning(false);
        }
    }

    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: root.back()
    }

    // Wi-Fi's tile icon is a live signal meter, so it's gotta be a component, not a plain
    // glyph. The data-driven tile grid below grabs it by key.
    Component {
        id: wifiIconComp
        WifiIcon {
            active: Network.connected
            strength: Network.connected ? (Network.isWifi ? Network.signalStrength : 1) : 0
            color: Network.wifiEnabled ? Theme.onAccent : Theme.accent
            dimColor: Network.wifiEnabled ? Theme.alpha(Theme.onAccent, 0.30) : Theme.inkFaint
        }
    }

    Column {
        id: column
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Theme.s4

        // header: back button + title + (sub-view) master toggle
        Item {
            width: parent.width
            height: 40

            Rectangle {
                id: backBtn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 40; height: 40; radius: 20
                color: backMa.containsMouse ? Theme.fillHigh : Theme.fillLow
                Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                Icon {
                    anchors.centerIn: parent
                    name: "back"
                    color: Theme.inkPrimary
                }
                MouseArea {
                    id: backMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.back()
                }
            }
            StyledText {
                anchors.left: backBtn.right
                anchors.leftMargin: Theme.s3
                anchors.verticalCenter: parent.verticalCenter
                variant: "header"
                text: root.view === "wifi" ? "Wi-Fi"
                    : root.view === "bluetooth" ? "Bluetooth"
                    : root.view === "audio" ? "Audio"
                    : root.view === "display" ? "Display" : "Control Center"
                color: Theme.inkPrimary
            }
            Toggle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.view === "wifi" || root.view === "bluetooth"
                checked: root.view === "wifi" ? Network.wifiEnabled : Bluetooth.enabled
                onToggled: root.view === "wifi" ? Network.toggleWifi() : Bluetooth.toggle()
            }
        }

        // view container: overlaid views, push/pop slide + fade
        Item {
            id: views
            width: parent.width
            clip: true
            implicitHeight: root.view === "main" ? mainCol.implicitHeight
                          : root.view === "wifi" ? wifiCol.implicitHeight
                          : root.view === "bluetooth" ? btCol.implicitHeight
                          : root.view === "audio" ? audioCol.implicitHeight
                          : displayCol.implicitHeight

            // MAIN
            Column {
                id: mainCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.s4
                enabled: root.view === "main"
                opacity: root.view === "main" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                transform: Translate {
                    x: root.view === "main" ? 0 : -root.slide
                    Behavior on x { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                }

                // toggle-tile grid, all driven by Config (columns, which tiles, their order
                // and size, all editable in Settings). Each tile's BEHAVIOUR is keyed by
                // `key` here; what EXISTS and the defaults live in Config.ccRegistry. Adding
                // a tile means one registry entry plus one case in each branch below.
                GridLayout {
                    id: grid
                    width: parent.width
                    columns: Math.max(1, Config.ccColumns)
                    columnSpacing: Theme.s3
                    rowSpacing: Theme.s3

                    Repeater {
                        model: Config.ccVisibleTiles
                        delegate: CcTile {
                            required property var modelData
                            readonly property string key: modelData.key
                            Layout.columnSpan: Math.min(modelData.span, grid.columns)
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            label: modelData.label
                            icon: key === "audio" ? "volume"
                                : key === "bluetooth" ? "bluetooth"
                                : key === "display" ? "display"
                                : key === "peace" ? "dnd"
                                : key === "nightlight" ? "night" : ""
                            iconSource: key === "wifi" ? wifiIconComp : null
                            hasMenu: key === "wifi" || key === "audio" || key === "bluetooth" || key === "display"
                            on: key === "wifi" ? Network.wifiEnabled
                              : key === "audio" ? !Audio.muted
                              : key === "bluetooth" ? Bluetooth.enabled
                              : key === "peace" ? GlobalState.dnd
                              : key === "nightlight" ? NightLight.enabled : false
                            sublabel: key === "wifi" ? (Network.wifiEnabled ? Network.label : "Off")
                                : key === "audio" ? (Audio.nodeLabel(Audio.sink) || "Output")
                                : key === "bluetooth" ? (Bluetooth.enabled ? (Bluetooth.hasConnection ? Bluetooth.label : "On") : "Off")
                                : key === "display" ? (Display.current ? ("Scale " + Display.fmtScale(Display.current.scale) + "×") : "Scale")
                                : key === "peace" ? (GlobalState.dnd ? "On" : "Off")
                                : key === "nightlight" ? (NightLight.enabled ? "On" : "Off") : ""
                            onToggled: {
                                if (key === "wifi") Network.toggleWifi();
                                else if (key === "audio") Audio.toggleMute();
                                else if (key === "bluetooth") Bluetooth.toggle();
                                else if (key === "peace") GlobalState.toggleDnd();
                                else if (key === "nightlight") NightLight.toggle();
                                else if (key === "display") { root.view = "display"; Display.refresh(); }
                            }
                            onMenu: {
                                if (key === "wifi") { root.view = "wifi"; Network.setScanning(true); }
                                else if (key === "audio") root.view = "audio";
                                else if (key === "bluetooth") root.view = "bluetooth";
                                else if (key === "display") { root.view = "display"; Display.refresh(); }
                            }
                        }
                    }
                }

                // the fat sliders
                CcSlider { visible: Config.ccSliders; width: parent.width; icon: "volume"; from: 0; to: 1; value: Audio.volume; onMoved: Audio.setVolume(value) }
                CcSlider { visible: Config.ccSliders; width: parent.width; icon: "brightness"; from: 0; to: 100; value: root.brightnessMon ? root.brightnessMon.percentage : 0; onMoved: if (root.brightnessMon) root.brightnessMon.setBrightness(value) }

                // Now playing (MPRIS): Android-16 media card with the art as the backdrop
                Column {
                    width: parent.width
                    spacing: Theme.s2
                    visible: Config.ccMedia && Media.hasPlayer

                    Rectangle {
                        id: mcard
                        width: parent.width
                        height: 148
                        radius: Theme.rXl
                        clip: true
                        color: Theme.surfaceOverlay

                        readonly property var p: Media.player
                        readonly property bool hasArt: mart.status === Image.Ready
                        readonly property color ink: hasArt ? "#f6f6f6" : Theme.inkPrimary
                        readonly property color ink2: hasArt ? Qt.rgba(0.96, 0.96, 0.96, 0.72) : Theme.inkDim
                        property real ratio: 0
                        function refresh() { ratio = (p && p.length > 0) ? Math.max(0, Math.min(1, p.position / p.length)) : 0; }
                        onVisibleChanged: refresh()
                        Timer { interval: 1000; repeat: true; running: mcard.visible && mcard.p && mcard.p.isPlaying; onTriggered: mcard.refresh() }

                        // album art background. Two passes so the BLURRED art is what ends up
                        // rounded: (1) blur the raw image into an offscreen texture, then (2) mask
                        // that blurred texture down to the card's rounded corners. Doing blur+mask
                        // in one MultiEffect left the art square, 'cause clip:true only clips the
                        // bounding RECT, not the rounded shape. Found that out the annoying way.
                        Image { id: mart; anchors.fill: parent; source: mcard.p ? (mcard.p.trackArtUrl || "") : ""; fillMode: Image.PreserveAspectCrop; cache: true; asynchronous: true; visible: false; layer.enabled: true }
                        MultiEffect { id: martBlur; anchors.fill: parent; source: mart; blurEnabled: true; blur: 0.7; blurMax: 48; autoPaddingEnabled: false; visible: false; layer.enabled: true }
                        Rectangle { id: martMask; anchors.fill: parent; radius: mcard.radius; visible: false; layer.enabled: true }
                        MultiEffect { anchors.fill: parent; source: martBlur; maskSource: martMask; maskEnabled: true; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0; visible: mcard.hasArt }
                        Rectangle { anchors.fill: parent; radius: mcard.radius; visible: mcard.hasArt; color: Qt.rgba(0, 0, 0, 0.5) }

                        // output device (up top)
                        Row {
                            id: outRow
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: playBtn.left
                            anchors.topMargin: Theme.s3; anchors.leftMargin: Theme.s4; anchors.rightMargin: Theme.s3
                            spacing: Theme.s2
                            Icon { anchors.verticalCenter: parent.verticalCenter; name: "volume"; size: Theme.fsCaption + 2; color: mcard.ink2 }
                            StyledText { anchors.verticalCenter: parent.verticalCenter; width: outRow.width - 24; elide: Text.ElideRight; variant: "caption"; text: Audio.nodeLabel(Audio.sink) || "Now playing"; color: mcard.ink2 }
                        }

                        // play / pause
                        Rectangle {
                            id: playBtn
                            anchors.right: parent.right; anchors.rightMargin: Theme.s4
                            anchors.verticalCenter: parent.verticalCenter
                            width: 56; height: 56; radius: 28
                            color: mcard.hasArt ? Qt.rgba(0.96, 0.96, 0.96, 0.92) : Theme.accent
                            Icon {
                                anchors.centerIn: parent
                                name: (mcard.p && mcard.p.isPlaying) ? "pause" : "play"
                                size: Theme.iconSize + 4
                                color: mcard.hasArt ? "#101010" : Theme.onAccent
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: mcard.p && mcard.p.canTogglePlaying; onClicked: if (mcard.p) mcard.p.togglePlaying() }
                        }

                        // title + artist
                        Column {
                            anchors.left: parent.left; anchors.leftMargin: Theme.s4
                            anchors.right: playBtn.left; anchors.rightMargin: Theme.s3
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            StyledText { width: parent.width; elide: Text.ElideRight; variant: "title"; text: mcard.p ? (mcard.p.trackTitle || "Unknown") : ""; color: mcard.ink }
                            StyledText { width: parent.width; elide: Text.ElideRight; variant: "label"; text: mcard.p ? (mcard.p.trackArtist || "") : ""; color: mcard.ink2 }
                        }

                        // transport + progress (down at the bottom)
                        Item {
                            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                            anchors.leftMargin: Theme.s4; anchors.rightMargin: Theme.s4; anchors.bottomMargin: Theme.s4
                            height: 24
                            Icon {
                                id: prevB
                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                name: "prev"; color: mcard.ink
                                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; enabled: mcard.p && mcard.p.canGoPrevious; onClicked: if (mcard.p) mcard.p.previous() }
                            }
                            Icon {
                                id: nextB
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                name: "next"; color: mcard.ink
                                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; enabled: mcard.p && mcard.p.canGoNext; onClicked: if (mcard.p) mcard.p.next() }
                            }
                            Rectangle {
                                anchors.left: prevB.right; anchors.right: nextB.left
                                anchors.leftMargin: Theme.s5; anchors.rightMargin: Theme.s5
                                anchors.verticalCenter: parent.verticalCenter
                                height: 6; radius: 3
                                color: mcard.hasArt ? Qt.rgba(1, 1, 1, 0.3) : Theme.fillHigh
                                Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: parent.width * mcard.ratio; radius: 3; color: mcard.hasArt ? "#f6f6f6" : Theme.accent }
                            }
                        }
                    }
                }

                // Notifications
                Column {
                    width: parent.width
                    spacing: Theme.s2
                    visible: Config.ccNotifications

                    Rectangle { width: parent.width; height: 1; color: Theme.hairline }

                    Item {
                        width: parent.width
                        height: 18
                        StyledText {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            variant: "caption"; text: "Notifications"; color: Theme.inkDim
                        }
                        StyledText {
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            visible: Notifications.list.length > 0
                            variant: "caption"; text: "Clear all"; color: Theme.accent
                            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: Notifications.clearAll() }
                        }
                    }
                    StyledText {
                        visible: Notifications.list.length === 0
                        variant: "label"; text: "No notifications"; color: Theme.inkDim
                    }
                    ListView {
                        visible: Notifications.list.length > 0
                        width: parent.width
                        height: Math.min(contentHeight, 200)
                        clip: true
                        spacing: Theme.s1
                        model: Notifications.list
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: Rectangle {
                            id: hrow
                            required property var modelData
                            width: ListView.view.width
                            height: hcol.implicitHeight + Theme.s3 * 2
                            radius: Theme.rLg
                            color: Theme.fillLow

                            readonly property string nIcon: modelData.appIcon
                                ? Quickshell.iconPath(modelData.appIcon, "dialog-information")
                                : (modelData.image || "")

                            // app icon, circular
                            Rectangle {
                                id: nbadge
                                anchors.left: parent.left; anchors.top: parent.top
                                anchors.leftMargin: Theme.s3; anchors.topMargin: Theme.s3
                                width: 32; height: 32; radius: 16
                                color: hrow.nIcon !== "" ? Theme.fillHigh : Theme.alpha(Theme.accent, 0.18)
                                clip: true
                                Image {
                                    anchors.fill: parent; anchors.margins: 5
                                    source: hrow.nIcon; visible: source != ""
                                    sourceSize.width: 24; sourceSize.height: 24
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }
                                StyledText {
                                    anchors.centerIn: parent
                                    visible: hrow.nIcon === ""
                                    variant: "caption"
                                    font.weight: Theme.wMedium
                                    text: (hrow.modelData.appName || "?").charAt(0).toUpperCase()
                                    color: Theme.accent
                                }
                            }
                            Column {
                                id: hcol
                                anchors.left: nbadge.right; anchors.leftMargin: Theme.s3
                                anchors.right: hclose.left; anchors.rightMargin: Theme.s2
                                anchors.top: parent.top; anchors.topMargin: Theme.s3
                                spacing: 1
                                StyledText {
                                    width: parent.width; elide: Text.ElideRight
                                    variant: "caption"; visible: text !== ""
                                    text: hrow.modelData.appName || ""
                                    color: Theme.inkDim
                                }
                                StyledText {
                                    width: parent.width; elide: Text.ElideRight
                                    variant: "label"; font.weight: Theme.wMedium
                                    text: hrow.modelData.summary || ""
                                    color: Theme.inkPrimary
                                }
                                StyledText {
                                    width: parent.width
                                    visible: (hrow.modelData.body || "") !== ""
                                    elide: Text.ElideRight
                                    variant: "caption"
                                    text: hrow.modelData.body
                                    textFormat: Text.PlainText
                                    color: Theme.inkDim
                                }
                            }
                            StyledText {
                                id: hclose
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.rightMargin: Theme.s3
                                anchors.topMargin: Theme.s3
                                text: "✕"
                                color: Theme.inkDim
                                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: Notifications.dismiss(hrow.modelData) }
                            }
                        }
                    }
                }
            }

            // WI-FI
            Column {
                id: wifiCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.s2
                enabled: root.view === "wifi"
                opacity: root.view === "wifi" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                transform: Translate {
                    x: root.view === "wifi" ? 0 : root.slide
                    Behavior on x { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                }

                ListView {
                    width: parent.width
                    height: Math.min(contentHeight, 320)
                    clip: true
                    spacing: Theme.s1
                    model: Network.wifiNetworks
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Rectangle {
                        id: wrow
                        required property var modelData
                        width: ListView.view.width
                        height: 40
                        radius: Theme.rMd
                        color: wrow.modelData.connected ? Theme.accent : Theme.fillLow
                        StyledText {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.s3
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - sig.width - Theme.s4
                            elide: Text.ElideRight
                            variant: "label"
                            text: (wrow.modelData.name && wrow.modelData.name !== "") ? wrow.modelData.name : "(hidden)"
                            color: wrow.modelData.connected ? Theme.onAccent : Theme.inkPrimary
                        }
                        StyledText {
                            id: sig
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.s3
                            anchors.verticalCenter: parent.verticalCenter
                            variant: "caption"
                            text: (wrow.modelData.connected ? "✓ " : (wrow.modelData.known ? "★ " : "")) + Math.round((wrow.modelData.signalStrength ?? 0) * 100) + "%"
                            color: wrow.modelData.connected ? Theme.onAccent : Theme.inkDim
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.wifiClicked(wrow.modelData) }
                    }
                }

                Rectangle {
                    visible: root.pskTarget !== null
                    width: parent.width
                    height: 40
                    radius: Theme.rMd
                    color: Theme.fillLow
                    TextInput {
                        id: pskField
                        anchors.left: parent.left
                        anchors.right: pskGo.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Theme.s3
                        anchors.rightMargin: Theme.s3
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Theme.inkPrimary
                        font.family: Theme.fontBody
                        font.pixelSize: Theme.fsLabel
                        clip: true
                        Keys.onEscapePressed: root.pskTarget = null
                        Keys.onReturnPressed: pskGoArea.doConnect()
                        Keys.onEnterPressed: pskGoArea.doConnect()
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: pskField.text === ""
                            variant: "label"
                            text: root.pskTarget ? `Password for ${root.pskTarget.name}` : ""
                            color: Theme.inkFaint
                        }
                    }
                    Rectangle {
                        id: pskGo
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 4
                        width: 64; height: 30
                        radius: Theme.rSm
                        color: Theme.accent
                        StyledText { anchors.centerIn: parent; variant: "caption"; text: "Connect"; color: Theme.onAccent }
                        MouseArea {
                            id: pskGoArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            function doConnect() {
                                if (root.pskTarget) root.pskTarget.connectWithPsk(pskField.text);
                                root.pskTarget = null;
                                pskField.text = "";
                            }
                            onClicked: doConnect()
                        }
                    }
                }

                StyledText {
                    visible: Network.wifiNetworks.length === 0
                    variant: "label"; text: Network.wifiEnabled ? "Scanning…" : "Wi-Fi is off"; color: Theme.inkDim
                }
            }

            // BLUETOOTH
            Column {
                id: btCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.s1
                enabled: root.view === "bluetooth"
                opacity: root.view === "bluetooth" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                transform: Translate {
                    x: root.view === "bluetooth" ? 0 : root.slide
                    Behavior on x { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                }

                Repeater {
                    model: Bluetooth.pairedDevices
                    delegate: Rectangle {
                        id: brow
                        required property var modelData
                        width: parent.width
                        height: 40
                        radius: Theme.rMd
                        color: brow.modelData.connected ? Theme.accent : Theme.fillLow
                        StyledText {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.s3
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - bstate.width - Theme.s4
                            elide: Text.ElideRight
                            variant: "label"
                            text: brow.modelData.deviceName || brow.modelData.name || brow.modelData.address
                            color: brow.modelData.connected ? Theme.onAccent : Theme.inkPrimary
                        }
                        StyledText {
                            id: bstate
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.s3
                            anchors.verticalCenter: parent.verticalCenter
                            variant: "caption"
                            text: brow.modelData.connected ? "Disconnect" : "Connect"
                            color: brow.modelData.connected ? Theme.onAccent : Theme.accent
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: brow.modelData.connected ? brow.modelData.disconnect() : brow.modelData.connect() }
                    }
                }
                StyledText {
                    visible: Bluetooth.pairedDevices.length === 0
                    variant: "label"; text: Bluetooth.enabled ? "No paired devices" : "Bluetooth is off"; color: Theme.inkDim
                }
            }

            // AUDIO
            Column {
                id: audioCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.s3
                enabled: root.view === "audio"
                opacity: root.view === "audio" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                transform: Translate {
                    x: root.view === "audio" ? 0 : root.slide
                    Behavior on x { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                }

                StyledText { variant: "caption"; text: "Output device"; color: Theme.inkDim }
                Column {
                    width: parent.width
                    spacing: Theme.s1
                    Repeater {
                        model: Audio.sinks
                        delegate: Rectangle {
                            id: orow
                            required property var modelData
                            readonly property bool current: modelData === Audio.sink
                            width: parent.width
                            height: 40
                            radius: Theme.rMd
                            color: current ? Theme.accent : Theme.fillLow
                            StyledText {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.s3
                                anchors.right: ocheck.left
                                anchors.rightMargin: Theme.s2
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                variant: "label"
                                text: Audio.nodeLabel(orow.modelData)
                                color: orow.current ? Theme.onAccent : Theme.inkPrimary
                            }
                            StyledText {
                                id: ocheck
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.s3
                                anchors.verticalCenter: parent.verticalCenter
                                text: orow.current ? "✓" : ""
                                color: Theme.onAccent
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Audio.setSink(orow.modelData) }
                        }
                    }
                }
                CcSlider { width: parent.width; icon: "volume"; from: 0; to: 1; value: Audio.volume; onMoved: Audio.setVolume(value) }

                Rectangle { width: parent.width; height: 1; color: Theme.hairline }

                StyledText { variant: "caption"; text: "Input device"; color: Theme.inkDim }
                Column {
                    width: parent.width
                    spacing: Theme.s1
                    Repeater {
                        model: Audio.sources
                        delegate: Rectangle {
                            id: irow
                            required property var modelData
                            readonly property bool current: modelData === Audio.source
                            width: parent.width
                            height: 40
                            radius: Theme.rMd
                            color: current ? Theme.accent : Theme.fillLow
                            StyledText {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.s3
                                anchors.right: icheck.left
                                anchors.rightMargin: Theme.s2
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                variant: "label"
                                text: Audio.nodeLabel(irow.modelData)
                                color: irow.current ? Theme.onAccent : Theme.inkPrimary
                            }
                            StyledText {
                                id: icheck
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.s3
                                anchors.verticalCenter: parent.verticalCenter
                                text: irow.current ? "✓" : ""
                                color: Theme.onAccent
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Audio.setSource(irow.modelData) }
                        }
                    }
                    StyledText {
                        visible: Audio.sources.length === 0
                        variant: "label"; text: "No input devices"; color: Theme.inkDim
                    }
                }
                CcSlider { width: parent.width; icon: "mic"; from: 0; to: 1; value: Audio.sourceVolume; onMoved: Audio.setSourceVolume(value) }
            }

            // DISPLAY
            Column {
                id: displayCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.s4
                enabled: root.view === "display"
                opacity: root.view === "display" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                transform: Translate {
                    x: root.view === "display" ? 0 : root.slide
                    Behavior on x { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                }

                // one group per monitor: a header plus a row of scale chips (current one's accent)
                Repeater {
                    model: Display.monitors
                    delegate: Column {
                        id: monGroup
                        required property var modelData
                        readonly property var mon: modelData
                        width: parent ? parent.width : 0
                        spacing: Theme.s2

                        StyledText {
                            variant: "caption"
                            text: monGroup.mon.name + "  ·  " + monGroup.mon.width + "×" + monGroup.mon.height
                                + (monGroup.mon.focused ? "  ·  focused" : "")
                            color: Theme.inkDim
                        }

                        // SCALE, the primary control here. Chips wrap to fit the panel width.
                        Flow {
                            width: parent.width
                            spacing: Theme.s2
                            Repeater {
                                model: Display.scaleOptions
                                delegate: Rectangle {
                                    id: chip
                                    required property var modelData      // a scale number
                                    readonly property bool current: Math.abs(modelData - monGroup.mon.scale) < 0.01
                                    width: chipText.implicitWidth + Theme.s4 * 2
                                    height: 44
                                    radius: Theme.rMd
                                    color: current ? Theme.accent : Theme.fillLow
                                    opacity: Display.busy ? 0.5 : 1
                                    StyledText {
                                        id: chipText
                                        anchors.centerIn: parent
                                        variant: "label"
                                        font.weight: Theme.wMedium
                                        text: Display.fmtScale(chip.modelData) + "×"
                                        color: chip.current ? Theme.onAccent : Theme.inkPrimary
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !Display.busy && !chip.current
                                        onClicked: Display.setScale(monGroup.mon.name, chip.modelData)
                                    }
                                }
                            }
                        }
                    }
                }
                StyledText {
                    visible: Display.monitors.length === 0
                    variant: "label"; text: "No displays detected"; color: Theme.inkDim
                }
            }
        }
    }
}
