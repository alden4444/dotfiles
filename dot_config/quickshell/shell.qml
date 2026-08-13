import Quickshell

import qs.modules.bar
import qs.modules.decorations

Variants {
    model: Quickshell.screens

    delegate: Scope {
        id: perScreen
        required property var modelData
        
        Bar { modelData: perScreen.modelData }
        ScreenCorners { modelData: perScreen.modelData }
    }
}
