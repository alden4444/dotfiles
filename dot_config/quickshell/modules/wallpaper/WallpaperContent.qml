import QtQuick
import QtQuick.Effects
import Quickshell
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// Wallpaper picker that lives INSIDE the bar island (the island morphs into it, see
// Bar.qml). Content-forward: a thumbnail grid where the thumbnails are the UI and the
// chrome gets out of the way. Current = accent ring, hover = a flat hairline ring (no
// lift). Click and it applies right away (Config.wallpaper → persisted → background crossfade).
Item {
    id: root

    property bool active: false
    implicitHeight: col.implicitHeight
    clip: true

    function close() { GlobalState.wallpaperPickerOpen = false; }
    function pick(path) {
        Config.wallpaper = path;
        Quickshell.execDetached(["bash", `${Quickshell.env("HOME")}/.config/wallust/wallpaper-record.sh`, Config.theme, path]);
    }

    onActiveChanged: if (active) Qt.callLater(() => keyCatcher.forceActiveFocus());

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

        // header
        Item {
            width: parent.width
            height: 28
            StyledText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                variant: "header"
                text: "Wallpaper"
                color: Theme.inkPrimary
            }
            StyledText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                variant: "caption"
                text: Config.theme
                color: Theme.inkDim
            }
        }

        GridView {
            id: gridv
            width: parent.width
            height: Math.min(contentHeight, 348)
            clip: true
            cellWidth: Math.floor(width / 3)
            cellHeight: Math.round(cellWidth * 0.62)
            model: Wallpapers.model
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: cell
                required property string filePath
                required property url fileUrl
                width: gridv.cellWidth
                height: gridv.cellHeight
                readonly property bool current: filePath === Config.wallpaper

                Item {
                    anchors.fill: parent
                    anchors.margins: Theme.s1

                    Image {
                        id: thumb
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 320
                        sourceSize.height: 200
                        source: cell.fileUrl
                        visible: false
                        layer.enabled: true
                    }
                    Rectangle {
                        id: thumbMask
                        anchors.fill: parent
                        radius: Theme.rMd
                        visible: false
                        layer.enabled: true
                    }
                    MultiEffect {
                        anchors.fill: parent
                        source: thumb
                        maskSource: thumbMask
                        maskEnabled: true
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                    }
                    // selection / hover ring, drawn on top and rounded to match the thumb
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.rMd
                        color: "transparent"
                        border.color: cell.current ? Theme.accent : (cellMa.containsMouse ? Theme.hairline : "transparent")
                        border.width: cell.current ? 2 : 1
                        Behavior on border.color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                    }
                    MouseArea {
                        id: cellMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pick(cell.filePath)
                    }
                }
            }
        }
    }
}
