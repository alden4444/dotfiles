import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../config"

// Native wallpaper renderer: one background-layer surface per monitor showing
// Config.wallpaper, with a crossfade when it changes. Two Image layers; the incoming
// image loads into whichever one's hidden, then we flip `showA` to fade it in. No
// external daemon, no swww, no hyprpaper.
PanelWindow {
    id: w

    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell:wallpaper"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    // Ignore exclusive zones so the wallpaper covers the WHOLE screen, even behind the
    // island's reserved strip. Otherwise it gets shoved down and you're left with a band.
    exclusionMode: ExclusionMode.Ignore
    color: Theme.background // fallback color before/behind the images

    property bool showA: true
    readonly property string source: Config.wallpaper

    function toUrl(p) { return (p && p.length > 0) ? (p.startsWith("/") ? "file://" + p : p) : ""; }
    function apply(p) {
        const url = toUrl(p);
        if (url === "")
            return;
        // load it into whichever layer is currently hidden
        if (showA) imgB.source = url; else imgA.source = url;
    }

    onSourceChanged: apply(source)
    Component.onCompleted: apply(source)

    Image {
        id: imgA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize.width: w.screen ? w.screen.width : 0
        sourceSize.height: w.screen ? w.screen.height : 0
        opacity: w.showA ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
        onStatusChanged: if (status === Image.Ready && !w.showA) w.showA = true
    }

    Image {
        id: imgB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize.width: w.screen ? w.screen.width : 0
        sourceSize.height: w.screen ? w.screen.height : 0
        opacity: w.showA ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
        onStatusChanged: if (status === Image.Ready && w.showA) w.showA = false
    }
}
