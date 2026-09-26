import QtQuick
import QtQuick.Effects
import Quickshell
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// Wallpaper picker that lives INSIDE the bar island (the island morphs into it, see
// Bar.qml). A CAROUSEL, not a grid: five thumbnails across, the middle one held at
// centre and full size while the rest fall away by distance (same opacity falloff the
// date strip uses). Flick it with the arrows, the wheel, or by dragging; nothing is
// applied until you press Enter, so you can browse past a dozen wallpapers without the
// desktop strobing behind you. The one currently in use keeps an accent dot.
// Running into either end rubber-bands instead of stopping dead.
Item {
    id: root

    property bool active: false
    implicitHeight: col.implicitHeight
    clip: true

    // five across, 16:10-ish. The strip is one cell tall; the centre cell sits at scale 1
    // and its neighbours shrink, so nothing needs headroom above it.
    // Sized off the panel's SETTLED width, not its live one. The cell height feeds
    // implicitHeight, which is what the island animates its height toward — read from the
    // animating width, the island could only learn how tall to be once it had finished
    // getting wide, so it expanded outward first and then downward, in two beats instead of
    // one motion. Off a constant, the final height is known on the first frame and both axes
    // travel together; the strip is still only as wide as the panel, so during the morph the
    // thumbnails are revealed rather than resized.
    readonly property int perView: 5
    readonly property int panelW: Math.max(240, Config.wallpaperPickerWidth - Theme.s4 * 2)
    readonly property int cellW: Math.floor(panelW / perView)
    readonly property int cellH: Math.round(cellW * 0.62)
    // Headroom for the hover lift. The strip has to clip horizontally, so without room set
    // aside the raised thumbnail (and its ring) would just get sliced off the top — the row
    // is cellH + 2*cellPad tall and the thumbnail sits centred in it, so the lift happens
    // INSIDE the clip. Same arrangement the theme switcher uses.
    readonly property int liftPx: 3
    readonly property int cellPad: 8
    readonly property int rowH: cellH + cellPad * 2

    readonly property int count: Wallpapers.model?.count ?? 0

    function close() { GlobalState.wallpaperPickerOpen = false; }

    // Move by one, or rubber-band if that's the end of the road.
    function step(dir) {
        if (root.count === 0) return;
        const next = strip.currentIndex + dir;
        if (next < 0 || next >= root.count) {
            endBounce.dir = dir;
            endBounce.restart();
            return;
        }
        strip.currentIndex = next;
    }

    // Apply the CENTRED one. This is the only thing that touches Config.wallpaper —
    // moving through the carousel is free.
    function apply() {
        const m = Wallpapers.model;
        if (!m || m.count === 0 || strip.currentIndex < 0) return;
        const path = m.get(strip.currentIndex, "filePath");
        if (!path) return;
        Config.wallpaper = path;
        Quickshell.execDetached(["bash", `${Quickshell.env("HOME")}/.config/wallust/wallpaper-record.sh`, Config.theme, path]);
    }

    // Open on whatever's already applied rather than at the far left. The folder model
    // populates asynchronously, so this gets called again when the count lands.
    function syncToCurrent() {
        const m = Wallpapers.model;
        if (!m || m.count === 0) return;
        for (let i = 0; i < m.count; i++) {
            if (m.get(i, "filePath") === Config.wallpaper) {
                strip.currentIndex = i;
                strip.positionViewAtIndex(i, ListView.Center);
                return;
            }
        }
    }

    onActiveChanged: if (active) Qt.callLater(() => { keyCatcher.forceActiveFocus(); root.syncToCurrent(); })

    Connections {
        target: Wallpapers.model
        function onCountChanged() { if (root.active) Qt.callLater(root.syncToCurrent); }
    }

    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: root.step(-1)
        Keys.onRightPressed: root.step(1)
        Keys.onReturnPressed: root.apply()
        Keys.onEnterPressed: root.apply()
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
                capCentreIn: parent
                variant: "header"
                text: "Wallpaper"
                color: Theme.inkPrimary
            }
            StyledText {
                anchors.right: parent.right
                capCentreIn: parent
                variant: "caption"
                text: Config.theme
                color: Theme.inkDim
            }
        }

        // the carousel
        Item {
            width: parent.width
            height: root.rowH

            ListView {
                id: strip
                anchors.fill: parent
                orientation: ListView.Horizontal
                model: Wallpapers.model
                clip: true

                // pin the current item dead centre and snap to it, so the strip always
                // rests on a thumbnail instead of halfway between two
                preferredHighlightBegin: (width - root.cellW) / 2
                preferredHighlightEnd: (width - root.cellW) / 2
                highlightRangeMode: ListView.StrictlyEnforceRange
                // Room at both ends so the FIRST and LAST items can actually reach the centre.
                // Without it, centring anything near the start needs a negative contentX, which
                // is outside the Flickable's bounds — it snapped back, and StrictlyEnforceRange
                // then re-picked whichever item was nearest the middle. That's what shunted the
                // selection one across the moment the panel opened, and what broke landing on
                // the first result after a search (result 0 needs exactly that scroll).
                leftMargin: Math.max(0, (width - root.cellW) / 2)
                rightMargin: Math.max(0, (width - root.cellW) / 2)
                snapMode: ListView.SnapOneItem
                highlightMoveDuration: Theme.dur(Theme.dSpring)
                // dragging past either end rubber-bands rather than hitting a wall
                boundsBehavior: Flickable.DragOverBounds
                boundsMovement: Flickable.FollowBoundsBehavior

                // run-into-the-end rubber band: shove the strip against the direction you
                // asked for, then let the shell's own spring drop it back (so it carries
                // whatever bounce motionBounce is set to)
                transform: Translate { id: bump }
                SequentialAnimation {
                    id: endBounce
                    property int dir: 1
                    NumberAnimation {
                        target: bump; property: "x"
                        to: -endBounce.dir * 22
                        duration: Theme.dur(Theme.dFast)
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: bump; property: "x"
                        to: 0
                        duration: Theme.dur(Theme.dSpring)
                        easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier
                    }
                }

                delegate: Item {
                    id: cell
                    required property int index
                    required property string filePath
                    required property url fileUrl

                    width: root.cellW
                    height: root.rowH

                    readonly property bool inUse: filePath === Config.wallpaper
                    readonly property bool centred: index === strip.currentIndex
                    // Distance from the centre of the viewport in CELL units, read off the live
                    // contentX rather than the index, so the falloff tracks a drag continuously
                    // instead of stepping when the current index flips.
                    readonly property real dist: Math.abs((x + width / 2) - (strip.contentX + strip.width / 2)) / Math.max(1, root.cellW)

                    opacity: 1 - Math.min(0.6, dist * 0.32)
                    scale: 1 - Math.min(0.2, dist * 0.1)
                    // nudges up under the pointer, so hovering visibly does something even
                    // though it still takes a click to select — same as the theme switcher
                    transform: Translate {
                        y: cellMa.containsMouse ? -root.liftPx : 0
                        Behavior on y { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                    }

                    Item {
                        // the thumbnail itself keeps its own size, centred in the padded row
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.cellW - Theme.s1 * 2
                        height: root.cellH - Theme.s1 * 2

                        Image {
                            id: thumb
                            readonly property bool ready: status === Image.Ready && source.toString() !== ""
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
                        // placeholder under the art, so a not-yet-decoded thumb is a quiet
                        // surface rather than a hole punched in the strip
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.rMd
                            color: Theme.surfaceBase
                            visible: !thumb.ready
                        }
                        MultiEffect {
                            anchors.fill: parent
                            source: thumb
                            maskSource: thumbMask
                            maskEnabled: true
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            // decoding is async, so fade the art up as it lands instead of
                            // letting it snap in a frame after the panel is already open
                            opacity: thumb.ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                        }

                        // ring on the CENTRED one (the one Enter will apply); a plain hairline
                        // on hover so the off-centre ones still read as targets
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.rMd
                            color: "transparent"
                            // hover has to be clearly brighter than idle; hairline was too close
                            // to invisible to read as a response
                            border.color: cell.centred ? Theme.accent
                                        : cellMa.containsMouse ? Theme.alpha(Theme.foreground, 0.45)
                                        : "transparent"
                            border.width: cell.centred ? 2 : 1
                            Behavior on border.color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                        }

                        // "this one's actually live" dot, so the applied wallpaper stays
                        // identifiable while you browse past it
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: Theme.s2
                            width: 8; height: 8
                            radius: 4
                            visible: cell.inUse
                            color: Theme.accent
                            border.width: 1
                            border.color: Theme.alpha(Theme.base, 0.45)
                        }

                        MouseArea {
                            id: cellMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            // click an outer one to bring it to the middle; click the middle
                            // one to apply it (same as Enter)
                            onClicked: {
                                if (cell.centred) root.apply();
                                else strip.currentIndex = cell.index;
                            }
                        }
                    }
                }
            }

            // wheel anywhere over the strip steps through it. NoButton so it never eats the
            // clicks the thumbnails need (same trick the media zone uses in Bar.qml).
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => {
                    const d = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y;
                    if (d !== 0) root.step(d < 0 ? 1 : -1);
                }
            }
        }

        // footer: what's centred, where you are, and how to commit it
        Item {
            width: parent.width
            height: 18

            StyledText {
                anchors.left: parent.left
                capCentreIn: parent
                width: parent.width * 0.6
                elide: Text.ElideMiddle
                variant: "caption"
                color: Theme.inkDim
                text: {
                    const m = Wallpapers.model;
                    if (!m || m.count === 0) return "No wallpapers in this theme's folder";
                    if (strip.currentIndex < 0) return "";
                    return m.get(strip.currentIndex, "fileName") ?? "";
                }
            }
            StyledText {
                anchors.right: parent.right
                capCentreIn: parent
                variant: "caption"
                color: Theme.inkFaint
                visible: root.count > 0
                text: `${strip.currentIndex + 1}/${root.count}   ·   Enter to apply`
            }
        }
    }
}
