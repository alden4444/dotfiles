import QtQuick
import Quickshell
pragma Singleton

Singleton {
    id: root

    readonly property bool useBar2: true
    // colors
    readonly property color background: "#0b0b0c"
    readonly property color surface: "#0c0c0d"
    readonly property color surfaceContainer: "#18181a"
    readonly property color containerHigh: "#202023"
    readonly property color bg2: surfaceContainer
    readonly property color bg4: containerHigh

    readonly property color primary: "#f2f2f2"      // accent
    readonly property color ink: "#0a0a0a"          // text sitting on a white chip
    readonly property color fg: "#e8e8e8"           // normal text
    readonly property color secondary: "#9a9a9e"    // quieter text
    readonly property color subtextDim: "#77777b"   // quietest textx
    readonly property color critical: "#e5645c"

    readonly property color outline: Qt.rgba(1, 1, 1, 0.09)

    readonly property color barTint: Qt.rgba(9 / 255, 9 / 255, 10 / 255, 0.78)

    // radius
    readonly property int rXs: 2
    readonly property int rSm: 6
    readonly property int rMd: 10
    readonly property int rLg: 16

    // spacing
    readonly property int s1: 4
    readonly property int s2: 8
    readonly property int s3: 12
    readonly property int s4: 16

    // layout
    readonly property int barHeight: 34

    // type
    readonly property string fontSans: "Google Sans Flex"
    readonly property string fontMono: "Google Sans Code"

    // screencornerradius
    readonly property int cornerRadius: 28

    // motion
    readonly property int motionFast: 120       // hover, toggles
    readonly property int motionStandard: 180   // panels
    readonly property int motionSlow: 240           // bigger moves
    readonly property var ease: [0.2, 0, 0, 1, 1, 1]

}
