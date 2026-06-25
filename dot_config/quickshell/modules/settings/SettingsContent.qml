import QtQuick
import "../../theme"
import "../../config"
import "../../components"

// Settings that live INSIDE the bar island (the island morphs into it, see Bar.qml). A
// GUI over Config so you never hand-edit the JSON: the bar-height and font-size sliders
// write Config (JsonAdapter persists it), and the Theme / Wallpaper rows hand off to those
// morphs. Flat tokens throughout. Want a new setting? Add a Config field and a row.
Item {
    id: root

    property bool active: false
    implicitHeight: col.implicitHeight
    clip: true

    function close() { GlobalState.settingsOpen = false; }

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
        spacing: Theme.s4

        StyledText {
            variant: "header"
            text: "Settings"
            color: Theme.inkPrimary
        }

        // --- Bar height ---
        Column {
            width: parent.width
            spacing: Theme.s2
            Item {
                width: parent.width; height: lblBar.implicitHeight
                StyledText { id: lblBar; variant: "label"; text: "Bar height"; color: Theme.inkDim }
                StyledText {
                    anchors.right: parent.right
                    variant: "label"
                    font.features: { "tnum": 1 }
                    text: Config.barHeight + " px"
                    color: Theme.inkPrimary
                }
            }
            Slider {
                width: parent.width
                from: 24; to: 64
                value: Config.barHeight
                onMoved: v => Config.barHeight = Math.round(v)
            }
        }

        // --- Font size ---
        Column {
            width: parent.width
            spacing: Theme.s2
            Item {
                width: parent.width; height: lblFont.implicitHeight
                StyledText { id: lblFont; variant: "label"; text: "Font size"; color: Theme.inkDim }
                StyledText {
                    anchors.right: parent.right
                    variant: "label"
                    font.features: { "tnum": 1 }
                    text: Config.fontSize + " px"
                    color: Theme.inkPrimary
                }
            }
            Slider {
                width: parent.width
                from: 10; to: 20
                value: Config.fontSize
                onMoved: v => Config.fontSize = Math.round(v)
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.hairline }

        // --- Theme (hands off to the theme switcher morph) ---
        SettingsRow {
            width: parent.width
            label: "Theme"
            value: Config.theme
            onActivated: { GlobalState.settingsOpen = false; GlobalState.themeSwitcherOpen = true; }
        }

        // --- Wallpaper (hands off to the wallpaper picker morph) ---
        SettingsRow {
            width: parent.width
            label: "Wallpaper"
            value: "Choose…"
            onActivated: { GlobalState.settingsOpen = false; GlobalState.wallpaperPickerOpen = true; }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.hairline }

        // Control Center layout (all the stuff you used to hand-edit in QML)
        StyledText {
            variant: "header"
            text: "Control Center"
            color: Theme.inkPrimary
        }

        // Grid columns
        Column {
            width: parent.width
            spacing: Theme.s2
            Item {
                width: parent.width; height: lblCols.implicitHeight
                StyledText { id: lblCols; variant: "label"; text: "Grid columns"; color: Theme.inkDim }
                StyledText {
                    anchors.right: parent.right
                    variant: "label"
                    font.features: { "tnum": 1 }
                    text: Config.ccColumns
                    color: Theme.inkPrimary
                }
            }
            Slider {
                width: parent.width
                from: 2; to: 6
                value: Config.ccColumns
                onMoved: v => Config.ccColumns = Math.round(v)
            }
        }

        // Section visibility (sliders / media / notifications)
        Repeater {
            model: [
                { label: "Sliders",       field: "sliders" },
                { label: "Media player",  field: "media" },
                { label: "Notifications", field: "notifications" }
            ]
            delegate: Item {
                required property var modelData
                width: col.width
                height: 30
                StyledText {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    variant: "label"; text: modelData.label; color: Theme.inkDim
                }
                Toggle {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    checked: modelData.field === "sliders" ? Config.ccSliders
                           : modelData.field === "media" ? Config.ccMedia : Config.ccNotifications
                    onToggled: v => {
                        if (modelData.field === "sliders") Config.ccSliders = v;
                        else if (modelData.field === "media") Config.ccMedia = v;
                        else Config.ccNotifications = v;
                    }
                }
            }
        }

        // Tiles: reorder (↑/↓), resize (Large = full-width), show/hide
        StyledText { variant: "label"; text: "Tiles"; color: Theme.inkDim }
        Repeater {
            model: Config.ccLayout
            delegate: Item {
                required property var modelData
                required property int index
                width: col.width
                height: 40

                Row {
                    id: moveRow
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.s1
                    Rectangle {
                        width: 30; height: 30; radius: Theme.rSm
                        enabled: index > 0
                        opacity: enabled ? 1 : 0.35
                        color: upMa.containsMouse ? Theme.fillHigh : Theme.fillLow
                        Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                        Icon { anchors.centerIn: parent; name: "back"; rotation: 90; size: 13; color: Theme.inkPrimary }
                        MouseArea { id: upMa; anchors.fill: parent; enabled: parent.enabled; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Config.ccMove(modelData.key, -1) }
                    }
                    Rectangle {
                        width: 30; height: 30; radius: Theme.rSm
                        enabled: index < Config.ccLayout.length - 1
                        opacity: enabled ? 1 : 0.35
                        color: dnMa.containsMouse ? Theme.fillHigh : Theme.fillLow
                        Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                        Icon { anchors.centerIn: parent; name: "back"; rotation: -90; size: 13; color: Theme.inkPrimary }
                        MouseArea { id: dnMa; anchors.fill: parent; enabled: parent.enabled; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Config.ccMove(modelData.key, 1) }
                    }
                }

                StyledText {
                    anchors.left: moveRow.right
                    anchors.leftMargin: Theme.s3
                    anchors.verticalCenter: parent.verticalCenter
                    variant: "label"
                    text: modelData.label
                    color: modelData.enabled ? Theme.inkPrimary : Theme.inkFaint
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.s3
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.s2
                        StyledText { anchors.verticalCenter: parent.verticalCenter; variant: "caption"; text: "Large"; color: Theme.inkDim }
                        Toggle {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: modelData.span === 2
                            onToggled: v => Config.ccSetSpan(modelData.key, v ? 2 : 1)
                        }
                    }
                    Toggle {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: modelData.enabled
                        onToggled: v => Config.ccSetEnabled(modelData.key, v)
                    }
                }
            }
        }
    }
}
