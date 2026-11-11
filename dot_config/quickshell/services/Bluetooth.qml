pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

// Bluetooth summary. Quickshell.Bluetooth (BlueZ) covers power, connect/disconnect,
// info, and basic pairing. Anything fancier and yer back to bluetoothctl (gotcha #10).
Singleton {
    id: root

    function asArray(m) { return !m ? [] : (m.values !== undefined ? m.values : m); }

    readonly property var adapter: Bluetooth.defaultAdapter ?? (asArray(Bluetooth.adapters)[0] ?? null)
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property var connectedDevices: asArray(Bluetooth.devices).filter(d => d.connected)
    readonly property bool hasConnection: connectedDevices.length > 0

    readonly property string label: {
        if (!enabled) return "BT off";
        if (connectedDevices.length === 0) return "BT on";
        if (connectedDevices.length === 1) {
            const d = connectedDevices[0];
            return d.deviceName || d.name || "BT";
        }
        return `BT ×${connectedDevices.length}`;
    }

    Process { id: rfkillProc }
    Process { id: btctlProc }

    function toggle() { setEnabled(!enabled); }
    function setEnabled(on) {
        if (on) {
            rfkillProc.command = ["rfkill", "unblock", "bluetooth"];
            rfkillProc.running = true;
        }
        if (adapter) {
            adapter.enabled = on;
        } else {
            btctlProc.command = ["bluetoothctl", "power", on ? "on" : "off"];
            btctlProc.running = true;
        }
    }

    // Paired devices for the control center list, connected ones up top.
    readonly property var pairedDevices: asArray(Bluetooth.devices)
        .filter(d => d.paired)
        .slice()
        .sort((a, b) => (b.connected ? 1 : 0) - (a.connected ? 1 : 0))
}
