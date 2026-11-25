//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import qs
import "modules/common"
import "services"
import "panelFamilies"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    // Stuff for every panel family
    ReloadPopup {}

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
        Updates.load()
    }


    // Panel families
    property list<string> families: ["ii", "waffle"]
    function cyclePanelFamily() {
        const currentIndex = families.indexOf(Config.options.panelFamily)
        const nextIndex = (currentIndex + 1) % families.length
        Config.options.panelFamily = families[nextIndex]
    }

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && Config.options.panelFamily === identifier && extraCondition
    }
    
    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }

    PanelFamilyLoader {
        identifier: "waffle"
        component: WaffleFamily {}
    }


    // Shortcuts
    IpcHandler {
        target: "panelFamily"

        function cycle(): void {
            root.cyclePanelFamily()
        }
    }

    GlobalShortcut {
        name: "panelFamilyCycle"
        description: "Cycles panel family"

        onPressed: root.cyclePanelFamily()
    }

    // Compatibility aliases for shared Hyprland keybinds
    GlobalShortcut {
        name: "launcher"
        description: "Toggle launcher / overview"
        onPressed: GlobalStates.overviewOpen = !GlobalStates.overviewOpen
    }
    GlobalShortcut {
        name: "theme"
        description: "Toggle theme / wallpaper selector"
        onPressed: GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen
    }
    GlobalShortcut {
        name: "wallpaper"
        description: "Toggle wallpaper selector"
        onPressed: GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen
    }
    GlobalShortcut {
        name: "settings"
        description: "Open ii settings window"
        onPressed: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")])
    }
    GlobalShortcut {
        name: "controlcenter"
        description: "Toggle right sidebar quick settings"
        onPressed: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
    }
    GlobalShortcut {
        name: "brightnessUp"
        description: "Increase brightness"
        onPressed: Brightness.increaseBrightness()
    }
    GlobalShortcut {
        name: "brightnessDown"
        description: "Decrease brightness"
        onPressed: Brightness.decreaseBrightness()
    }
}

