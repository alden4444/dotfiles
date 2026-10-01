import QtQuick

import qs.theme

Rectangle {
    id: pill

    property string icon: ""
    property color accent: Theme.fg
    property string text: ""

    implicitWidth: row.width
    implicitHeight: Theme.moduleHeight
    radius: Theme.radius
    color: Theme.bg1

    Shadow {}

    Row {
        id: row
        height: parent.height
        leftPadding: 4
        rightPadding: 12
        spacing: 10

        IconDisc {
            anchors.verticalCenter: parent.verticalCenter
            icon: pill.icon
            accent: pill.accent
            size: 22
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: pill.text
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.textSize
            font.weight: 600
        }
    }
}
