import QtQuick
import QtQuick.Effects
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// The art circle: the status circle's twin on the island's LEFT. Same disc as the island
// and the status circle (base fill, hairline, shadow), with the current player's album art
// inset as a rounded square, the way the media card draws it. Up while a music player is
// open (the bar fades it and shifts the island so the pair stays centred). Art crossfades
// on track change over a music-note placeholder. Hover presents it (the bar pushes it
// outward and it grows a little); a click opens the media player, which morphs OUT OF this
// circle: while `lent`, the disc is hidden (the panel's fill takes over at the same rect)
// and the art cross-fades out pinned to the spot, riding `lentT` (the bar's transform
// clock), and comes back only once the circle has settled.
Item {
    id: root

    property real size: 37
    property bool interactive: true
    property bool lent: false
    property real lentT: 0
    property bool opening: false   // the transform is going out (art fades with it) vs coming back (art waits)

    // hover presentation clock: the bar reads it for the outward push and the drop. While
    // lent the hover state is FROZEN at what it was when the transform started.
    property bool zoneHovered: false   // the bar's static hover zone (see Bar.qml islandZone)
    property bool heldHover: false
    readonly property bool hovered: lent ? heldHover : (zoneHovered && interactive)
    property real hoverT: hovered ? 1 : 0
    Behavior on hoverT { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
    transformOrigin: Item.Center
    property real grow: 1.1
    scale: 1 + (grow - 1) * hoverT

    // art square inside the disc: inset so the disc reads as the frame, corners scaled
    // like the media card's (0.28 of the side, capped at rMd)
    readonly property real inset: Math.round(size * 0.24)
    readonly property real artSize: size - inset * 2
    readonly property real artRadius: Math.min(Theme.rMd, artSize * 0.28)

    // art: out over the first 25% of the open; hidden through the close; revealed on
    // dEffects once the bar's clamped clock reads 0 (the container IS the disc then),
    // latched once per close (same shape as StatusPill)
    property real reveal: 1
    property bool revealed: true
    NumberAnimation { id: revealAnim; target: root; property: "reveal"; from: 0; to: 1; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
    readonly property bool settled: !lent || (!opening && lentT <= 0)
    onLentChanged: if (lent) { heldHover = zoneHovered && interactive; revealed = opening; }
    // the close begins while still lent: drop the latch and the glyphs, or they sit at full
    // opacity on the circle's spot while the container is still shrinking towards it
    onOpeningChanged: if (lent && !opening) { revealed = false; reveal = 0; }
    onSettledChanged: if (settled && !revealed) { revealed = true; revealAnim.restart(); }
    readonly property real glyphOpacity: opening ? 1 - Math.max(0, Math.min(1, lentT / 0.25)) : (revealed ? reveal : 0)

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        id: disc
        anchors.fill: parent
        radius: width / 2
        color: Theme.base
        border.width: 1
        border.color: Theme.hairline
        antialiasing: true
        visible: !root.lent
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

    Item {
        id: art
        anchors.centerIn: parent
        width: root.artSize
        height: root.artSize
        opacity: root.glyphOpacity

        Rectangle {
            anchors.fill: parent
            radius: root.artRadius
            color: Theme.surfaceOverlay
            opacity: artImg.ready ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
            Icon {
                anchors.centerIn: parent
                name: "music"
                size: Math.round(root.artSize * 0.6)
                color: Theme.accent
            }
        }
        Image {
            id: artImg
            readonly property bool ready: status === Image.Ready && source.toString() !== ""
            anchors.fill: parent
            source: Media.player?.trackArtUrl ?? ""
            sourceSize: Qt.size(root.artSize * 2, root.artSize * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: false
            layer.enabled: true      // art masking, not a shadow: always on
        }
        Rectangle {
            id: artMask
            anchors.fill: parent
            radius: root.artRadius
            visible: false
            layer.enabled: true      // art masking, not a shadow: always on
        }
        MultiEffect {
            anchors.fill: parent
            source: artImg
            maskEnabled: true
            maskSource: artMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            opacity: artImg.ready ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive && !root.lent
        cursorShape: Qt.PointingHandCursor
        onClicked: GlobalState.mediaPlayerOpen = !GlobalState.mediaPlayerOpen
    }
}
