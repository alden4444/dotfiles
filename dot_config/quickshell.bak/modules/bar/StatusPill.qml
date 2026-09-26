import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// The status circle: a small round satellite that sits to the right of the island, same
// height as the collapsed pill, same fill, hairline and shadow. Wi-Fi glyph in the middle,
// battery as a ring around it: a dim full track and a bright arc that hangs from twelve
// o'clock with BOTH tails growing down towards six as the charge rises, so 100% closes the
// ring and the gap left at the bottom is the charge used (green while charging, red when
// low). Hover presents it (the bar pushes it outward and it grows a little); a click opens
// the control center, which morphs OUT OF this circle: while `lent`, the disc is hidden
// (the island fill takes over at the same rect) and the glyphs cross-fade out pinned to
// the spot, riding `lentT` (the bar's transform clock).
Item {
    id: root

    property real size: 37
    property color fill: Theme.base
    property bool interactive: true
    property bool lent: false
    property real lentT: 0
    property bool opening: false   // the transform is going out (glyphs fade with it) vs coming back (glyphs wait)

    // hover presentation clock: the bar reads it for the outward push and the drop. While
    // lent the hover state is FROZEN at what it was when the transform started (the pointer
    // sits inside the panel after the click; the disc must hand back at the geometry the
    // container is shrinking to), and goes live again at hand-off.
    property bool heldHover: false
    property bool zoneHovered: false   // the bar's static hover zone (see Bar.qml islandZone)
    readonly property bool hovered: lent ? heldHover : (zoneHovered && interactive)
    property real hoverT: hovered ? 1 : 0
    Behavior on hoverT { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

    implicitWidth: size
    implicitHeight: size
    transformOrigin: Item.Center
    property real grow: 1.1
    scale: 1 + (grow - 1) * hoverT

    // ring geometry: inset from the edge so the arc never kisses the hairline
    readonly property real ringW: 2.4
    readonly property real ringR: size / 2 - ringW / 2 - 3.5
    readonly property real pct: Battery.available ? Battery.percentage / 100 : 1
    property real shown: pct
    Behavior on shown { NumberAnimation { duration: Theme.dur(Theme.dBase); easing.type: Theme.easeOut } }
    readonly property color arcColor: Battery.low ? Theme.bad : Battery.charging ? Theme.good : Theme.inkPrimary
    // glyphs: out over the first 25% of the open; HIDDEN through the whole close (the spring's
    // tail is long and the contents must not sit in a circle that is still settling); then
    // revealed on dEffects once the container has handed the disc back
    // "settled": the bar's clock is clamped at the circle, so the first time it reads 0 on
    // the close the container IS the disc, exactly; the spring's remaining tail changes
    // nothing visible. Latched once per close so a later wobble can't restart the reveal.
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

    Rectangle {
        id: disc
        anchors.fill: parent
        radius: width / 2
        color: root.fill
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

    // battery ring: dim track + the charge arc, centred on twelve o'clock, gap at the bottom
    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        visible: Battery.available
        opacity: root.glyphOpacity
        ShapePath {
            strokeColor: Theme.inkFaint; strokeWidth: root.ringW; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: root.size / 2; centerY: root.size / 2; radiusX: root.ringR; radiusY: root.ringR; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {
            strokeColor: root.arcColor; strokeWidth: root.ringW; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            Behavior on strokeColor { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
            PathAngleArc {
                centerX: root.size / 2; centerY: root.size / 2; radiusX: root.ringR; radiusY: root.ringR
                // both tails leave twelve o'clock symmetrically: the arc is centred on -90
                startAngle: -90 - 180 * root.shown
                sweepAngle: Math.max(0.5, 360 * root.shown)
            }
        }
    }

    WifiIcon {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 0.5
        scale: 0.8
        opacity: root.glyphOpacity
        strength: Network.signalStrength
        active: Network.wifiEnabled && Network.isWifi
        color: Theme.inkPrimary
        dimColor: Theme.inkFaint
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive && !root.lent
        cursorShape: Qt.PointingHandCursor
        onClicked: GlobalState.controlCenterOpen = !GlobalState.controlCenterOpen
    }
}
