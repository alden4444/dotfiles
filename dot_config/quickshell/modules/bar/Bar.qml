import QtQuick
import QtQuick.Layouts
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

    RowLayout {
        anchors {
            left: parent.left
            leftMargin: Theme.s4
            verticalCenter: parent.verticalCenter
        }
        spacing: Theme.s3

        Workspaces {
            monitorName: bar.modelData.name
            Layout.alignment: Qt.AlignVCenter
        }

        WindowTitle {
            Layout.alignment: Qt.AlignVCenter
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        id: clockChip

        anchors {
            right: parent.right
            rightMargin: Theme.s3
            verticalCenter: parent.verticalCenter
        }

        implicitWidth: clockRow.implicitWidth + Theme.s3 * 2
        implicitHeight: 24

        radius: Theme.rSm

        color: bar.ccOpen ? Theme.containerHight: (clockHover.containsMouse ? Theme.surfaceContainer : "transparent") 
        Behavior on color { ColorAnimation { duration: Theme. motionFast } }

        RowLayout {
            id: clockRow
            anchors.centerIn: parent
            spacing: Theme.s2

            Text {
                text: Qt.formatDateTime(clock.date, "HH:mm")

                font {
                    family: Theme.fontSans
                    pixelSize: 14
                    weight: 600
                }

                color: Theme.fg
            }

            Text {
                text: Qt.formatDateTime(clock.date, "ddd MMM d").toLowerCase()
                font {
                    family: Theme.fontSans
                    pixelSize: 13
                    weight: 400
                    features: { "tnum": 1 }
                }

                color: Theme.secondary
            }
        }

        MouseArea {
            id: clockHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: bar.ccOpen = !bar.ccOpen
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