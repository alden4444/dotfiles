pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Curated wallust colorschemes for the theme switcher. Each entry carries a tiny
// preview (background + accent) pulled from the colorscheme JSON. Actually applying a
// theme is the UI's job (Config.theme + theme-apply.sh).
Singleton {
    id: root

    // [{ name, bg, accent }], alphabetical.
    property var list: []

    function refresh() { lsProc.running = true; }

    Process {
        id: lsProc
        running: true
        command: ["bash", "-c",
            "for f in ~/.config/wallust/colorschemes/*.json; do " +
            "n=$(basename \"$f\" .json); " +
            "bg=$(jq -r '.special.background' \"$f\" 2>/dev/null); " +
            "ac=$(jq -r '.colors[6]' \"$f\" 2>/dev/null); " +
            "echo \"$n|$bg|$ac\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.trim().split("\n")) {
                    if (!line) continue;
                    const p = line.split("|");
                    if (p.length >= 3)
                        out.push({ name: p[0], bg: p[1], accent: p[2] });
                }
                out.sort((a, b) => a.name.localeCompare(b.name));
                root.list = out;
            }
        }
    }
}
