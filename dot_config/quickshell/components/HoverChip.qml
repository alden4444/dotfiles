import QtQuick
import qs.config

Rectangle {
    id: root

    property string text: ""

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 16
    radius: 6
    color: mouse.containsMouse ? Theme.bg4 : Theme.bg2

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: Theme.fg
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
    }

    Behavior on color {
        ColorAnimation {
            duration: 150
        }

    }

}
