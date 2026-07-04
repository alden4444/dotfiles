import QtQuick
import Quickshell
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// Theme switcher that lives INSIDE the bar island (the island morphs into it, see
// Bar.qml). Content-forward: a grid of curated wallust colorschemes, each previewing
// its own {bg, accent}. Current = accent ring, hover = a flat hairline ring. Click one
// and it runs theme-apply.sh and persists Config.theme; the shell restyles live, no restart.
Item {
    id: root

    property bool active: false
    implicitHeight: col.implicitHeight
    clip: true

    function close() { GlobalState.themeSwitcherOpen = false; }
    function apply(name) {
        Quickshell.execDetached(["bash", `${Quickshell.env("HOME")}/.config/wallust/theme-apply.sh`, name]);
    }

    onActiveChanged: {
        if (active) {
            Themes.refresh();
            Qt.callLater(() => keyCatcher.forceActiveFocus());
        }
    }

    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: root.close()
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.s3

        StyledText {
            variant: "header"
            text: "Theme"
            color: Theme.inkPrimary
        }

        GridView {
            id: gridv
            width: parent.width
            height: Math.min(contentHeight, 320)
            clip: true
            cellWidth: Math.floor(width / 3)
            cellHeight: 96
            model: Themes.list
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: cell
                required property var modelData
                width: gridv.cellWidth
                height: gridv.cellHeight
                readonly property bool current: modelData.name === Config.theme

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Theme.s1
                    radius: Theme.rMd
                    color: cell.modelData.bg
                    border.color: cell.current ? Theme.accent : (cellMa.containsMouse ? Theme.hairline : Theme.alpha(Theme.foreground, 0.10))
                    border.width: cell.current ? 2 : 1
                    Behavior on border.color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.s2

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 40; height: 8; radius: 4
                            color: cell.modelData.accent
                        }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            variant: "caption"
                            text: cell.modelData.name
                            color: cell.modelData.accent   // the swatch's own accent, which reads fine on its own bg
                        }
                    }

                    MouseArea {
                        id: cellMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.apply(cell.modelData.name)
                    }
                }
            }
        }
    }
}
