pragma Singleton
import Quickshell
import Quickshell.Io

// User settings, persisted to ~/.config/quickshell/config.json via FileView +
// JsonAdapter. Fields round-trip to JSON on their own; add more as the settings panel
// grows. Live-reloads when something changes the file on disk.
Singleton {
    id: root

    property alias barHeight: adapter.barHeight
    property alias fontSize: adapter.fontSize
    property alias theme: adapter.theme
    property alias wallpaper: adapter.wallpaper

    // Control center layout (all editable from the settings panel)
    property alias ccColumns: adapter.ccColumns            // grid width
    property alias ccSliders: adapter.ccSliders            // show the volume/brightness sliders
    property alias ccMedia: adapter.ccMedia                // show the now-playing media card
    property alias ccNotifications: adapter.ccNotifications// show the notifications section
    property alias ccTiles: adapter.ccTiles                // JSON [{key,span,enabled}]: stored order + overrides

    // The canonical quick-settings tiles. The CODE owns what tiles EXIST and each one's
    // default size; the stored ccTiles only carries the user's order + overrides. So a
    // tile you add here later just shows up on its own (appended, enabled). To add one:
    // drop an entry here plus a case in ControlCenterContent's delegate, and that's it.
    readonly property var ccRegistry: [
        { key: "wifi",       label: "Wi-Fi",       span: 2 },
        { key: "audio",      label: "Audio",       span: 2 },
        { key: "bluetooth",  label: "Bluetooth",   span: 2 },
        { key: "display",    label: "Display",     span: 2 },
        { key: "peace",      label: "Peace",       span: 1 },
        { key: "nightlight", label: "Night Light", span: 1 }
    ]
    function _ccReg(key) {
        for (let i = 0; i < ccRegistry.length; i++)
            if (ccRegistry[i].key === key) return ccRegistry[i];
        return null;
    }

    // The resolved, ordered tile layout: stored order/overrides first (unknown keys get
    // dropped), then any registry tiles not stored yet. Shape is [{key,label,span,enabled}].
    readonly property var ccLayout: {
        let stored = [];
        try { stored = JSON.parse(ccTiles || "[]"); } catch (e) { stored = []; }
        const out = [];
        const seen = ({});
        for (let i = 0; i < stored.length; i++) {
            const s = stored[i];
            if (!s) continue;
            const reg = _ccReg(s.key);
            if (!reg || seen[s.key]) continue;
            seen[s.key] = true;
            out.push({ key: s.key, label: reg.label,
                       span: (s.span === 1 || s.span === 2) ? s.span : reg.span,
                       enabled: s.enabled !== false });
        }
        for (let i = 0; i < ccRegistry.length; i++) {
            const r = ccRegistry[i];
            if (seen[r.key]) continue;
            out.push({ key: r.key, label: r.label, span: r.span, enabled: true });
        }
        return out;
    }
    // the tiles that actually render, in order
    readonly property var ccVisibleTiles: ccLayout.filter(t => t.enabled)

    function _ccClone() {
        return ccLayout.map(t => ({ key: t.key, span: t.span, enabled: t.enabled }));
    }
    function _ccPersist(arr) { ccTiles = JSON.stringify(arr); }

    function ccSetEnabled(key, on) {
        const a = _ccClone();
        for (let i = 0; i < a.length; i++) if (a[i].key === key) a[i].enabled = !!on;
        _ccPersist(a);
    }
    function ccSetSpan(key, span) {
        const a = _ccClone();
        for (let i = 0; i < a.length; i++) if (a[i].key === key) a[i].span = (span === 1 ? 1 : 2);
        _ccPersist(a);
    }
    function ccMove(key, dir) {
        const a = _ccClone();
        let i = -1;
        for (let k = 0; k < a.length; k++) if (a[k].key === key) i = k;
        const j = i + dir;
        if (i < 0 || j < 0 || j >= a.length) return;
        const tmp = a[i]; a[i] = a[j]; a[j] = tmp;
        _ccPersist(a);
    }

    FileView {
        path: `${Quickshell.env("HOME")}/.config/quickshell/config.json`
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter() // persist changes back to disk (e.g. a wallpaper pick)

        JsonAdapter {
            id: adapter
            property int barHeight: 32
            property int fontSize: 14
            property string theme: "dark"
            property string wallpaper: ""
            property int ccColumns: 4
            property bool ccSliders: true
            property bool ccMedia: true
            property bool ccNotifications: true
            property string ccTiles: ""
        }
    }
}
