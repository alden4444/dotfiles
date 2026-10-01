import QtQuick
import Quickshell

import qs.components
import qs.theme

PanelWindow {
    id: bar

    anchors { top: true; left: true; right: true }
    margins { top: Theme.margin; left: Theme.margin; right: Theme.margin }

    implicitHeight: Theme.moduleHeight + Theme.shadowRoom
    exclusiveZone: Theme.moduleHeight

    color: "transparent"

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing
        spacing: Theme.spacing
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.spacing

        Pill {
            icon: "schedule"
            accent: Theme.orange
            text: "10:21"
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacing
        spacing: Theme.spacing
    }
}
