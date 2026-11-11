import QtQuick
import Quickshell
import "../../theme"
import "../../services"
import "../../components"

// Polkit auth prompt shown INSIDE the bar island (it morphs into this, see Bar.qml).
// Same security rules as the old standalone dialog, don't loosen any of 'em:
//  * shows the REAL action (message + action id) so an app can't fake a generic prompt;
//  * the island holds EXCLUSIVE keyboard focus while morphed (Bar sets that) so
//    keystrokes can't leak to whatever's behind it;
//  * submits ONLY through flow.submit(). polkitd decides, we never check the password;
//  * dismiss (Esc / click-outside / Cancel) cancels the request (fail closed).
Item {
    id: root

    property bool active: false
    implicitHeight: content.implicitHeight
    clip: true

    readonly property var flow: Polkit.flow

    readonly property string statusText: {
        const f = Polkit.flow;
        if (!f) return "";
        if (!f.isResponseRequired && !f.isCompleted) return "Authenticating…";
        if ((f.supplementaryMessage || "") !== "") return f.supplementaryMessage;
        if (f.failed) return "Authentication failed, try again";
        return "";
    }
    readonly property bool statusIsError: {
        const f = Polkit.flow;
        return f ? (f.failed || f.supplementaryIsError) : false;
    }

    function cancel() { if (Polkit.flow) Polkit.flow.cancelAuthenticationRequest(); }
    function submit() {
        if (Polkit.flow && Polkit.flow.isResponseRequired) {
            Polkit.flow.submit(pwField.text);
            pwField.text = "";
        }
    }

    onActiveChanged: {
        if (active) {
            pwField.text = "";
            Qt.callLater(() => pwField.forceActiveFocus());
        }
    }

    // Wrong password? Clear it and refocus so they can have another go.
    Connections {
        target: Polkit.flow
        ignoreUnknownSignals: true
        function onAuthenticationFailed() {
            pwField.text = "";
            pwField.forceActiveFocus();
        }
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.s3

        // header: lock icon + title
        Row {
            spacing: Theme.s2
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "lock"; color: Theme.accent
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                variant: "header"
                text: "Authentication Required"
                color: Theme.inkPrimary
            }
        }

        // the real action they're authorizing, so a rogue app can't spoof a vague one
        StyledText {
            width: parent.width
            wrapMode: Text.Wrap
            variant: "body"
            text: root.flow ? (root.flow.message || "An application is requesting elevated privileges.") : ""
            color: Theme.inkPrimary
        }
        StyledText {
            width: parent.width
            visible: root.flow && (root.flow.actionId || "") !== ""
            elide: Text.ElideRight
            variant: "caption"
            text: root.flow ? root.flow.actionId : ""
            color: Theme.inkDim
        }

        // password field, masked unless polkit says the response should show
        Rectangle {
            width: parent.width
            height: 44
            radius: Theme.rMd
            color: Theme.fillLow
            border.color: root.statusIsError ? Theme.bad : Theme.hairline
            border.width: 1

            TextInput {
                id: pwField
                anchors.fill: parent
                anchors.leftMargin: Theme.s3
                anchors.rightMargin: Theme.s3
                verticalAlignment: TextInput.AlignVCenter
                echoMode: (root.flow && root.flow.responseVisible) ? TextInput.Normal : TextInput.Password
                passwordCharacter: "•"
                color: Theme.inkPrimary
                font.family: Theme.fontBody
                font.pixelSize: Theme.fsBody
                clip: true
                enabled: root.flow ? root.flow.isResponseRequired : false
                onAccepted: root.submit()
                Keys.onEscapePressed: root.cancel()

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: pwField.text === ""
                    variant: "body"
                    text: (root.flow && root.flow.inputPrompt) ? root.flow.inputPrompt : "Password"
                    color: Theme.inkFaint
                }
            }
        }

        // status line: "Authenticating..." while it checks, error on a failure
        StyledText {
            width: parent.width
            wrapMode: Text.Wrap
            visible: root.statusText !== ""
            variant: "caption"
            text: root.statusText
            color: root.statusIsError ? Theme.bad : Theme.inkDim
        }

        // buttons
        Row {
            anchors.right: parent.right
            spacing: Theme.s2

            Rectangle {
                width: cancelLabel.implicitWidth + Theme.s4
                height: 34
                radius: Theme.rMd
                color: cancelMa.containsMouse ? Theme.fillHigh : Theme.fillLow
                Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                StyledText { id: cancelLabel; anchors.centerIn: parent; variant: "label"; text: "Cancel"; color: Theme.inkPrimary }
                MouseArea { id: cancelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cancel() }
            }
            Rectangle {
                width: authLabel.implicitWidth + Theme.s4
                height: 34
                radius: Theme.rMd
                color: Theme.accent
                StyledText { id: authLabel; anchors.centerIn: parent; variant: "label"; font.weight: Theme.wMedium; text: "Authenticate"; color: Theme.onAccent }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.submit() }
            }
        }
    }
}
