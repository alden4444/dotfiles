pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Automatically holds a systemd-inhibit block lock (idle + sleep) while BeamMP-Launcher
// or BeamNG.drive is running, preventing hypridle / logind from locking the screen,
// blanking the display (DPMS), or suspending the device—even if the game is minimized
// to a special workspace or only the launcher is open.
Singleton {
    id: root

    property bool active: false

    Process {
        id: probe
        command: ["pgrep", "-f", "BeamMP-Launcher|BeamNG\\.drive\\.x64"]
        onExited: (code) => {
            root.active = (code === 0);
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!probe.running)
                probe.running = true;
        }
    }

    // Hold a block inhibitor lock on idle and sleep while active.
    // Using `cat` with stdinEnabled: true ensures the lock is automatically dropped
    // if Quickshell exits or restarts.
    Process {
        id: inhibitor
        command: [
            "systemd-inhibit",
            "--what=idle:sleep",
            "--mode=block",
            "--who=Quickshell (BeamMP)",
            "--why=BeamMP / BeamNG.drive is running",
            "cat"
        ]
        stdinEnabled: true
        running: root.active
    }
}
