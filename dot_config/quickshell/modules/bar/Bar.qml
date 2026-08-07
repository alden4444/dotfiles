import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.config

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: Theme.barTint

    WlrLayershell.namespace: "ink-bar"
    WlrLayershell.layer: WlrLayer.Top
    exclusiveZone: implicitHeight

    Workspaces {
        monitorName: bar.modelData.name
        anchors {
            left: parent.left
            leftMargin: Theme.s4
            verticalCenter: parent.verticalCenter
        }
    }

    // outline
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        height: 1
        color: Theme.outline
    }
}