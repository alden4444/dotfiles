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
        // Pull each scheme's bg + accent with python3, NOT jq. jq isn't guaranteed to be
        // installed, and the day it went missing every swatch rendered empty/black (bg and
        // accent came back as empty strings). python3 is basically always there.
        command: ["python3", "-c", `
import glob, json, os
for f in sorted(glob.glob(os.path.expanduser('~/.config/wallust/colorschemes/*.json'))):
    n = os.path.basename(f)[:-5]
    try:
        d = json.load(open(f))
        bg = d.get('special', {}).get('background', '')
        c = d.get('colors')
        ac = c[6] if isinstance(c, list) and len(c) > 6 else ''
    except Exception:
        bg, ac = '', ''
    print(n + '|' + bg + '|' + ac)
`]
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
