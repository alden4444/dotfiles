import QtQuick
import "../../theme"
import "../../components"

// A settings row that hands off to another surface: a label on the left, a pill button
// on the right (value + chevron) that fires `activated()` when you click it.
Item {
    id: root

    property string label: ""
    property string value: ""
    signal activated()

    implicitHeight: Math.max(lbl.implicitHeight, btn.height)

    StyledText {
        id: lbl
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        variant: "label"
        text: root.label
        color: Theme.inkDim
    }

    Rectangle {
        id: btn
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: row.implicitWidth + Theme.s3 * 2
        height: row.implicitHeight + Theme.s2
        radius: Theme.rPill
        color: ma.containsMouse ? Theme.fillHigh : Theme.fillLow
        Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.s1
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                variant: "label"
                text: root.value
                color: Theme.inkPrimary
            }
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "back"
                rotation: 180          // flip the back-arrow into a right-pointing chevron
                size: 14
                color: Theme.inkDim
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activated()
        }
    }
}
