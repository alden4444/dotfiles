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
        const ps = players;
        // Real players win over the playerctld aggregator.
        const real = ps.filter(p => p.dbusName && p.dbusName.indexOf("playerctld") < 0);
        const pool = real.length > 0 ? real : ps;
        return pool.find(p => p.isPlaying) ?? pool.find(p => p.canControl) ?? pool[0] ?? null;
    }
    readonly property bool hasPlayer: player !== null
}
