import Quickshell

import qs.modules.bar
import qs.modules.decorations
import qs.config

Variants {
    model: Quickshell.screens

    delegate: Scope {
        id: perScreen
        required property var modelData
        
        Bar {
            visible: true
            modelData: perScreen.modelData
        }

        ScreenCorners {
            visible: !Theme.useMercury
            modelData: perScreen.modelData
        }
    }
}
