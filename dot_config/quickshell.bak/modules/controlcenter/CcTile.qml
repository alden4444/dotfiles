import QtQuick
import "../../theme"
import "../../components"

// A Material-You quick-settings tile: rounded, fills with accent when `on`, with an icon
// badge plus a label and sublabel. On tiles that have a settings menu (`hasMenu`), pressing
// the ICON badge toggles on/off while pressing the rest of the tile opens menu().
// On plain tiles, pressing anywhere just toggles.
Rectangle {
    id: tile

    property string label: ""
    property string sublabel: ""
    property string icon: ""              // custom Icon name (the preferred path)
    property string glyph: ""             // old nerd-font fallback
    property Component iconSource: null   // optional custom component (e.g. WifiIcon) instead of the icon
    property bool on: false
    property bool hasMenu: false
    signal toggled()
    signal menu()

    implicitHeight: 64
    radius: Theme.rXl
    color: on ? Theme.accent : Theme.surfaceOverlay
    Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }

    // body click: open the menu if there is one, else toggle. Declared first so the
    // badge's MouseArea stacks on top of it.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.hasMenu ? tile.menu() : tile.toggled()
    }

    // icon badge: its own click always toggles on/off, menu or no menu
    Rectangle {
        id: badge
        anchors.left: parent.left
        anchors.leftMargin: Theme.s3
        anchors.verticalCenter: parent.verticalCenter
        width: 40; height: 40; radius: 20
        color: tile.on ? Theme.alpha(Theme.onAccent, 0.18) : Theme.alpha(Theme.accent, 0.18)
        Icon {
            anchors.centerIn: parent
            visible: tile.iconSource === null && tile.icon !== ""
            name: tile.icon
            color: tile.on ? Theme.onAccent : Theme.accent
        }
        StyledText {
            anchors.centerIn: parent
            visible: tile.iconSource === null && tile.icon === ""
            font.family: Theme.fontGlyph
            font.pixelSize: Theme.iconSize
            text: tile.glyph
            color: tile.on ? Theme.onAccent : Theme.accent
        }
        Loader {
            anchors.centerIn: parent
            active: tile.iconSource !== null
            sourceComponent: tile.iconSource
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.toggled()
        }
    }

    // labels: no MouseArea here, so clicks fall through to the body
    Column {
        anchors.left: badge.right
        anchors.leftMargin: Theme.s3
        anchors.right: parent.right
        anchors.rightMargin: Theme.s3
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        StyledText {
            variant: "body"
            font.weight: Theme.wMedium
            text: tile.label
            color: tile.on ? Theme.onAccent : Theme.inkPrimary
        }
        StyledText {
            width: parent.width
            elide: Text.ElideRight
            variant: "caption"
            visible: text !== ""
            text: tile.sublabel
            color: tile.on ? Theme.onAccent : Theme.inkDim
        }
    }
}
