pragma Singleton
import Quickshell

// Night light (blue-light filter) via hyprsunset. On: fire up hyprsunset at a warm
// temperature (a detached daemon that hangs onto the gamma). Off: kill it, which
// lets go of the gamma and puts colour back to normal. No native binding, so it's
// one of the few legit Process uses (same deal as brightness). State is session-local.
Singleton {
    id: root

    // standard "mode" interface (see GameMode.qml): label + iconName + enabled +
    // toggle(). shell.qml's toggleMode() drives the island indicator off these.
    readonly property string label: "Night Light"
    readonly property string iconName: "night"

    property bool enabled: false
    property int temperature: 3000   // warm, in K

    function toggle() { enabled = !enabled; apply(); }

    function apply() {
        if (enabled)
            Quickshell.execDetached(["sh", "-c", "pkill hyprsunset 2>/dev/null; hyprsunset -t " + temperature]);
        else
            Quickshell.execDetached(["pkill", "hyprsunset"]);
    }
}
