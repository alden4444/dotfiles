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
            visible: !Theme.useBar2
            modelData: perScreen.modelData
        }

        Bar2 {
            visible: Theme.useBar2
            modelData: perScreen.modelData
        }
        ScreenCorners { modelData: perScreen.modelData }
    }
}
