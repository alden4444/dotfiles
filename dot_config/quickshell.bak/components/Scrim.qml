import QtQuick
import "../theme"

// Dim backdrop for overlays/auth. The blur-behind is handled by the Hyprland layerrule
// on the surface's namespace; this here is just the dim veil plus click-to-dismiss,
// fading in. Sits behind a centered card.
Rectangle {
    id: root

    property real dim: 0.45
    signal clicked()

    color: Theme.alpha(Theme.background, dim)
    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dBase); easing.type: Theme.easeOut } }

    MouseArea { anchors.fill: parent; onClicked: root.clicked() }
}
