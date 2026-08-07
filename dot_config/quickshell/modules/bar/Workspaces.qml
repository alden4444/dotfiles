import QtQuick
import Quickshell.Hyprland

import qs.config

Row {
    id: root

    // connector name (e.g. DP-1)
    required property string monitorName

    spacing: Theme.s1


    add: Transition {
        NumberAnimation {
            properties: "opacity"
            duration: Theme.motionSlow

            from: 0
            to: 1

            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.ease
        } 

        NumberAnimation {
            properties: "y"
            duration: Theme.motionSlow

            from: 4
            to: 0

            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.ease
        }
    }

    move: Transition {
        NumberAnimation {
            properties: "x"
            duration: Theme.motionStandard

            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.ease
        }
    }

    Repeater {
        model: Hyprland.workspaces

        delegate: Item {
            id: chip

            required property var modelData

            readonly property bool mine: !!modelData.monitor && modelData.monitor.name === root.monitorName && modelData.id > 0
            readonly property bool current: modelData.active
            readonly property bool occupied: (modelData.toplevels?.values?.length ?? 0) > 0

            visible: mine
            implicitWidth: 24
            implicitHeight: 22

            Rectangle {
                anchors.fill: parent
                radius: Theme.rSm
                color: Theme.primary
                opacity: chip.current ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
            }

            Text {
                anchors.centerIn: parent
                text: chip.modelData.id
                font {
                    family: Theme.fontSans
                    pixelSize: 13
                    weight: 600
                }
                color: chip.current ? Theme.ink : (chip.occupied ? Theme.fg : Theme.subtextDim)
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: chip.modelData.activate()
            }
        }
    }
}