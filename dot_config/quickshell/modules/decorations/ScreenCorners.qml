import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.config

Scope {
    id: root

    required property var modelData
    readonly property int radius: Theme.cornerRadius
    property bool visible: true
 
    component Corner: PanelWindow {
        id: win
        property real rot: 0

        visible: root.visible
        screen: root.modelData
        color: "transparent"

        implicitWidth: root.radius
        implicitHeight: root.radius

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "ink-corner"
        exclusionMode: ExclusionMode.Ignore

        mask: Region {} // empty imput region
        
        Canvas {
            anchors.fill: parent
            rotation: win.rot

            onPaint: {
                const ctx = getContext("2d")
                const s = width

                ctx.clearRect(0, 0, s, s)
                ctx.fillStyle = Theme.barTint
                ctx.beginPath()
                ctx.moveTo(0, 0)
                ctx.lineTo(s, 0)
                ctx.arc(s, s, s, 1.5 * Math.PI, Math.PI, true)
                ctx.closePath()
                ctx.fill()

                ctx.strokeStyle = Theme.outline
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.moveTo(s, 0)
                ctx.arc(s, s, s, 1.5 * Math.PI, Math.PI, true)
                ctx.stroke()
            }
        }
    }

    Corner { anchors.top: true; anchors.left: true; margins.top: Theme.barHeight; rot: 0 }
    Corner { anchors.top: true; anchors.right: true; margins.top: Theme.barHeight; rot: 90 }
    Corner { anchors.bottom: true; anchors.left: true; rot: 270 }
    Corner { anchors.bottom: true; anchors.right: true; rot: 180 }
}


    
