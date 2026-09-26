import QtQuick
import QtQuick.Effects
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// The media player: grows out of the art circle (Bar.qml) when a music player is open, or
// morphs the island like any other panel when the circle is off. One card: the album art
// large on the left, blurred and veiled as the backdrop behind everything (the CC media
// card's treatment, so the two read as one family); title / artist / album beside it; a
// seekable progress track with the times; prev / play / next underneath. Position is
// polled while the panel is up (MPRIS has no change signal). Esc and click-outside close.
Item {
    id: root

    property bool active: false
    implicitHeight: card.implicitHeight
    clip: true

    readonly property var p: Media.player
    readonly property bool playing: p ? p.isPlaying : false
    readonly property string title: p ? (p.trackTitle || "Unknown") : "Not playing"
    readonly property string artist: p ? (p.trackArtist || "") : ""
    readonly property string album: p ? (p.trackAlbum || "") : ""
    readonly property string artUrl: p ? (p.trackArtUrl || "") : ""
    readonly property string who: p ? (p.identity || "") : ""

    function close() { GlobalState.mediaPlayerOpen = false; }
    function togglePlay() { if (p && p.canTogglePlaying) p.togglePlaying(); }

    // position: read fresh on a tick (it advances on read), never bound to the player
    property real pos: 0
    property real len: 0
    function refresh() {
        if (!p) { pos = 0; len = 0; return; }
        len = p.length > 0 ? p.length : 0;
        pos = Math.max(0, Math.min(len, p.position));
    }
    onPChanged: refresh()
    onActiveChanged: { refresh(); if (active) Qt.callLater(() => keyCatcher.forceActiveFocus()); }
    Timer { interval: 500; repeat: true; running: root.active; onTriggered: root.refresh() }
    function fmt(s) {
        s = Math.max(0, Math.round(s)); const m = Math.floor(s / 60); const r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }

    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: root.close()
        Keys.onSpacePressed: root.togglePlay()
    }

    Item {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: Theme.s4 * 2 + Math.max(art.height, meta.implicitHeight + Theme.s3 + seek.height + Theme.s3 + transport.height)

        // ── backdrop: the art blurred (one pass), masked to the card (a second), then a veil
        //    tinted with the scheme's accent so the ink stays readable either way ──
        readonly property bool hasArt: bigArt.status === Image.Ready && root.artUrl !== ""
        Rectangle { id: cardBg; anchors.fill: parent; radius: Theme.rXl; color: Theme.surfaceOverlay }
        Image { id: bigArt; anchors.fill: parent; source: root.artUrl; fillMode: Image.PreserveAspectCrop; cache: true; asynchronous: true; visible: false; layer.enabled: true }
        MultiEffect { id: bigBlur; anchors.fill: parent; source: bigArt; blurEnabled: true; blur: 0.8; blurMax: 56; autoPaddingEnabled: false; visible: false; layer.enabled: true }
        Rectangle { id: cardMask; anchors.fill: parent; radius: Theme.rXl; visible: false; layer.enabled: true }
        MultiEffect { anchors.fill: parent; source: bigBlur; maskSource: cardMask; maskEnabled: true; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0; visible: card.hasArt }
        Rectangle { anchors.fill: parent; radius: Theme.rXl; visible: card.hasArt; color: Theme.alpha(Theme.mix(Theme.base, Theme.accent, 0.32), 0.72) }
        Rectangle { anchors.fill: parent; radius: Theme.rXl; color: "transparent"; border.width: 1; border.color: Theme.rim; z: 5 }

        // ── art, large ──
        Item {
            id: art
            x: Theme.s4
            y: Theme.s4
            width: 128; height: 128
            Rectangle { anchors.fill: parent; radius: Theme.rMd; color: Theme.fillHigh
                Icon { anchors.centerIn: parent; name: "music"; size: 30; color: Theme.inkDim; visible: !artFx.visible } }
            Image { id: artImg; anchors.fill: parent; source: root.artUrl; sourceSize: Qt.size(256, 256); fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true; visible: false; layer.enabled: true }
            Rectangle { id: artMask; anchors.fill: parent; radius: Theme.rMd; visible: false; layer.enabled: true }
            MultiEffect { id: artFx; anchors.fill: parent; source: artImg; maskSource: artMask; maskEnabled: true; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0; visible: artImg.status === Image.Ready && root.artUrl !== "" }
            Rectangle { anchors.fill: parent; radius: Theme.rMd; color: "transparent"; border.width: 1; border.color: Theme.rim }
        }

        // ── title / artist / album ──
        Column {
            id: meta
            anchors.left: art.right
            anchors.leftMargin: Theme.s4
            anchors.right: parent.right
            anchors.rightMargin: Theme.s4
            y: Theme.s4
            spacing: 2
            StyledText { width: parent.width; elide: Text.ElideRight; variant: "title"; font.weight: Theme.wSemiBold; text: root.title; color: Theme.inkPrimary }
            StyledText { width: parent.width; elide: Text.ElideRight; variant: "label"; visible: text !== ""; text: root.artist; color: Theme.inkDim }
            StyledText { width: parent.width; elide: Text.ElideRight; variant: "caption"; visible: text !== ""; text: root.album; color: Theme.inkFaint }
            StyledText { width: parent.width; elide: Text.ElideRight; variant: "caption"; visible: text !== "" && !!root.p; text: root.who; color: Theme.inkFaint }
        }

        // ── progress: the fill is the pointer's while it drags; a click or drop seeks ──
        Item {
            id: seek
            anchors.left: art.right
            anchors.leftMargin: Theme.s4
            anchors.right: parent.right
            anchors.rightMargin: Theme.s4
            y: Math.max(meta.y + meta.implicitHeight + Theme.s3, art.y + art.height - transport.height - Theme.s3 - height)
            height: 22
            readonly property bool canSeek: !!root.p && root.p.canSeek && root.len > 0
            property real localRatio: -1
            readonly property real ratio: localRatio >= 0 ? localRatio : (root.len > 0 ? root.pos / root.len : 0)
            Rectangle {
                id: track
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: seekMa.containsMouse || seekMa.pressed ? 8 : 5
                radius: height / 2
                color: Theme.fillHigh
                Behavior on height { NumberAnimation { duration: Theme.dur(Theme.dFast) } }
                Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: parent.width * seek.ratio; radius: parent.radius; color: Theme.accent }
            }
            MouseArea {
                id: seekMa
                anchors.fill: parent
                hoverEnabled: true
                enabled: seek.canSeek
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                function ratioAt(x) { return Math.max(0, Math.min(1, x / width)); }
                onPressed: mouse => seek.localRatio = ratioAt(mouse.x)
                onPositionChanged: mouse => { if (pressed) seek.localRatio = ratioAt(mouse.x); }
                onReleased: mouse => {
                    const r = ratioAt(mouse.x);
                    if (root.p) root.p.position = r * root.len;
                    root.pos = r * root.len;
                    seek.localRatio = -1;
                }
            }
            StyledText { anchors.left: parent.left; anchors.top: track.bottom; anchors.topMargin: 3; variant: "caption"; text: root.fmt(seek.ratio * root.len); color: Theme.inkDim; visible: root.len > 0 }
            StyledText { anchors.right: parent.right; anchors.top: track.bottom; anchors.topMargin: 3; variant: "caption"; text: root.fmt(root.len); color: Theme.inkFaint; visible: root.len > 0 }
        }

        // ── transport ──
        Row {
            id: transport
            anchors.left: art.right
            anchors.leftMargin: Theme.s4
            anchors.right: parent.right
            anchors.rightMargin: Theme.s4
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.s4
            height: 44
            spacing: Theme.s5
            layoutDirection: Qt.LeftToRight
            Item { width: (parent.width - 44 - 2 * (Theme.iconSize + Theme.s5)) / 2; height: 1 }
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "prev"; color: Theme.inkPrimary
                opacity: root.p && root.p.canGoPrevious ? 1 : 0.35
                MouseArea { anchors.fill: parent; anchors.margins: -8; enabled: root.p && root.p.canGoPrevious; cursorShape: Qt.PointingHandCursor; onClicked: root.p.previous() }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 44; height: 44; radius: 22
                color: root.playing ? Theme.accent : Theme.fillHigh
                Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                Icon { anchors.centerIn: parent; name: root.playing ? "pause" : "play"; color: root.playing ? Theme.onAccent : Theme.inkPrimary }
                MouseArea { anchors.fill: parent; enabled: !!root.p; cursorShape: Qt.PointingHandCursor; onClicked: root.togglePlay() }
            }
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "next"; color: Theme.inkPrimary
                opacity: root.p && root.p.canGoNext ? 1 : 0.35
                MouseArea { anchors.fill: parent; anchors.margins: -8; enabled: root.p && root.p.canGoNext; cursorShape: Qt.PointingHandCursor; onClicked: root.p.next() }
            }
        }
    }
}
