import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland

import qs.config

RowLayout {
    id: root

    // live values
    readonly property var active: ToplevelManager.activeToplevel
    readonly property string srcApp: active?.appId ?? "desktop"
    readonly property string srcTitle: active?.title ?? ""

    // held values
    property string shownApp: ""
    property string shownTitle: ""
    property real fade: 0

    spacing: Theme.s3

    onSrcAppChanged: swap.restart()
    onSrcTitleChanged: if (srcApp === shownApp && !swap.running) shownTitle = srcTitle

    Component.onCompleted: {
        shownApp = srcApp;
        shownTitle = srcTitle;
        fade = srcApp.length ? 1 : 0;
    }

    SequentialAnimation {
        id: swap

        NumberAnimation {
            target: root
            property: "fade"
            to: 0
            duration: Theme.motionFast

            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.ease
        }

        ScriptAction {
            script: {
                root.shownApp = root.srcApp
                root.shownTitle = root.srcTitle
            }
        }

        NumberAnimation {
            target: root
            property: "fade"
            to: 1
            duration: Theme.motionStandard

            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.ease
        }
    }

    Rectangle {
        implicitWidth: 1
        implicitHeight: 14

        color: Theme.outline
        opacity: root.fade

        Layout.alignment: Qt.AlignVCenter
    }

    RowLayout {
        spacing: Theme.s2
        opacity: root.fade

        Text {
            text: root.shownApp

            color: root.shownApp === "desktop" ? Theme.subtextDim : Theme.fg
            Behavior on color { ColorAnimation { duration: Theme.motionFast } }

            font {
                family: Theme.fontSans
                pixelSize: 13
                weight: 600
            }
        }

        Text {
            text: root.shownTitle
            color: Theme.secondary

            font {
                family: Theme.fontSans
                pixelSize: 13
                weight: 400
            }

            elide: Text.ElideRight
            Layout.maximumWidth: 360
        }
    }
}
