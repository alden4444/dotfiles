import QtQuick
import Quickshell

import qs.modules.bar

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData

            Bar {
                screen: perScreen.modelData
            }
        }
    }
}
