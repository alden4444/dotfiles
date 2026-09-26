pragma Singleton
import Quickshell
import Quickshell.Services.Mpris

// MPRIS media players. Hands the control center one "current" player, preferring a
// real player that's actually playing over the playerctld proxy (that one's just an
// aggregator, not the real thing). The Media service deferred back in Phase 2; its
// consumer (control center) finally exists.
Singleton {
    id: root

    function asArray(m) { return !m ? [] : (m.values !== undefined ? m.values : m); }
    readonly property var players: asArray(Mpris.players)

    readonly property var player: {
        // drop the playerctld aggregator, it's a proxy not a real player
        const ps = players.filter(p => p.dbusName && p.dbusName.indexOf("playerctld") < 0);
        const nameOf = p => (p.dbusName || "") + " " + (p.identity || "");
        const isSpotify = p => /spotify/i.test(nameOf(p));
        // A dedicated music app is a candidate the whole time it's open, paused or not:
        // the bar keeps its art up for it. Everything else (yes Brave, you) only counts
        // while it's actually playing, otherwise an idle browser MPRIS stub hijacks the
        // card with some weird icon. A browser tab on YouTube Music looks exactly like a
        // tab on a YouTube video from here (no URL in the metadata), so it can't be told
        // apart while paused; the desktop app can.
        const isMusicApp = p => /spotify|spotube|spot\b|psst|youtube.?music|ytmdesktop|tidal|deezer|apple.?music|cider|plexamp|amberol|rhythmbox|lollypop|elisa|strawberry|clementine|audacious|tauon|quodlibet|museeks|nuclear|feishin|supersonic|sonixd|mpd|ncmpcpp|cmus|mpv-music/i.test(nameOf(p));
        const pool = ps.filter(p => isMusicApp(p) || p.isPlaying);
        // whatever's actually playing wins (Spotify first if more than one is), then an
        // idle Spotify, then any other idle music app, then nobody at all.
        return pool.find(p => p.isPlaying && isSpotify(p))
            ?? pool.find(p => p.isPlaying)
            ?? pool.find(isSpotify)
            ?? pool.find(isMusicApp)
            ?? null;
    }
    readonly property bool hasPlayer: player !== null
}
