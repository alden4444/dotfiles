import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "../../components"

// Lock screen. WlSessionLock freezes all compositor input 'til you unlock, with one
// WlSessionLockSurface per monitor. All the state + PAM auth live in the LockState
// singleton ('cause the surface is its own isolated scope and can't reach ids). Fail
// closed: only LockState clears `locked`, and only on PamResult.Success.
WlSessionLock {
    id: lock
    locked: LockState.locked

    surface: WlSessionLockSurface {
        id: surf
        color: Theme.background

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Column {
            anchors.centerIn: parent
            width: 360
            spacing: Theme.s6

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.s1

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: Theme.fontDisplay          // big clock, in the mono data face
                    font.pixelSize: Theme.fontSize * 5
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Theme.inkPrimary
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    variant: "body"
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Theme.inkDim
                }
            }

            Rectangle {
                width: parent.width
                height: 46
                radius: Theme.rMd
                color: Theme.fillLow
                border.color: LockState.errorMsg !== "" ? Theme.bad : Theme.hairline
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }

                TextInput {
                    id: pwField
                    anchors.fill: parent
                    anchors.leftMargin: Theme.s3
                    anchors.rightMargin: Theme.s3
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: Theme.inkPrimary
                    font.family: Theme.fontBody
                    font.pixelSize: Theme.fsBody
                    clip: true
                    enabled: LockState.prompting && !LockState.authenticating
                    focus: true
                    onAccepted: {
                        LockState.submit(text);
                        text = "";
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: pwField.text === ""
                        variant: "body"
                        text: LockState.authenticating ? "Authenticating…"
                            : (LockState.errorMsg !== "" ? LockState.errorMsg
                            : (LockState.message !== "" ? LockState.message : "Enter password"))
                        color: LockState.errorMsg !== "" ? Theme.bad : Theme.inkFaint
                    }
                }
            }
        }

        Component.onCompleted: pwField.forceActiveFocus()
    }
}
