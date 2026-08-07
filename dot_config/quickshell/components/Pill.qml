import QtQuick
import qs.config

Rectangle {
    id: root

    property string text: ""

    implicitHeight: 24
    implicitWidth: label.implicitWidth + 20
    radius: height / 2
    color: Theme.bg2

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: Theme.fg
    }

}
