import QtQuick
import "../theme"

// Controlled horizontal slider. `value` is driven by the owner (bind it to a service
// property); a drag emits `moved(value)`. Do NOT bind value two-way: route `moved` to
// the service setter instead, or yer gonna get a feedback loop.
Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 18

    readonly property real ratio: to === from ? 0 : Math.max(0, Math.min(1, (value - from) / (to - from)))

    function applyAt(px) {
        const r = Math.max(0, Math.min(1, px / width));
        root.moved(from + r * (to - from));
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: Theme.rPill
        color: Theme.glassHigh

        Rectangle {
            width: parent.width * root.ratio
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }
    }

    Rectangle {
        width: 16
        height: 16
        radius: Theme.rPill
        anchors.verticalCenter: parent.verticalCenter
        x: (root.width - width) * root.ratio
        color: ma.pressed ? Theme.accentDeep : Theme.inkPrimary
        border.color: Theme.accent
        border.width: 2
        scale: ma.pressed ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: Theme.dur(Theme.dFast); easing.type: Theme.easeOut } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: root.applyAt(mouseX)
        onPositionChanged: if (pressed) root.applyAt(mouseX)
    }
}
