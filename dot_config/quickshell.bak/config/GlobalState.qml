pragma Singleton
import Quickshell

// Runtime UI state: which panels are open. Toggled by global shortcuts / IPC
// (Phase 1+). Not the same as Config: nothing here is a user preference, and it all
// resets on reload (stash it in Config/PersistentProperties if it has to survive).
Singleton {
    id: root

    property bool launcherOpen: false
    property bool controlCenterOpen: false
    property bool logoutOpen: false
    property bool wallpaperPickerOpen: false
    property bool themeSwitcherOpen: false
    property bool settingsOpen: false
    // which Settings page to land on when it next opens ("" = wherever it was left). The
    // control center's "Edit in Settings" chip sets it so you arrive on the layout editor.
    property string settingsPage: ""
    property bool calendarOpen: false
    property bool mediaPlayerOpen: false

    // Only ONE island panel open at a time. We enforce it here, not at the call sites, so
    // it holds no matter how a panel got opened: a toggle, an IPC open(), or one picker
    // handing off to another. Whenever one flips true, the rest get forced false. Setting
    // a bool that's already false is a no-op, so this never recurses on itself. (polkit
    // isn't a GlobalState panel; the bar already mutes everything else while an auth
    // prompt is up.) settings is DELIBERATELY excluded: it's its own floating window now,
    // not an island morph, so it coexists with the island. Clicking the island (which opens
    // one of these panels) must NOT close the settings window, and vice versa.
    // The control center and the media player are the exception to each other: each grows
    // out of its own circle into its own host, so both can be up at once. (When one of them
    // has to morph the island instead, the bar closes the other itself.)
    function keepOnly(which) {
        const circles = (which === "cc" || which === "media");
        if (which !== "launcher")  launcherOpen = false;
        if (which !== "cc" && !circles)        controlCenterOpen = false;
        if (which !== "logout")    logoutOpen = false;
        if (which !== "wallpaper") wallpaperPickerOpen = false;
        if (which !== "theme")     themeSwitcherOpen = false;
        if (which !== "calendar")  calendarOpen = false;
        if (which !== "media" && !circles)     mediaPlayerOpen = false;
    }
    onLauncherOpenChanged:        if (launcherOpen)         keepOnly("launcher");
    onControlCenterOpenChanged:   if (controlCenterOpen)    keepOnly("cc");
    onLogoutOpenChanged:          if (logoutOpen)           keepOnly("logout");
    onWallpaperPickerOpenChanged: if (wallpaperPickerOpen)  keepOnly("wallpaper");
    onThemeSwitcherOpenChanged:   if (themeSwitcherOpen)    keepOnly("theme");
    onCalendarOpenChanged:        if (calendarOpen)         keepOnly("calendar");
    onMediaPlayerOpenChanged:     if (mediaPlayerOpen)      keepOnly("media");

    // Do Not Disturb: suppresses notification popups, though history still records them.
    property bool dnd: false
    function toggleDnd() { dnd = !dnd; }

    // Lock is a transient request (a signal, not stored state) so a config reload can't
    // flip some "locked" bool back to false and quietly drop the lock on you.
    signal lockRequested()
    function requestLock() { lockRequested(); }

    function toggleLauncher() { launcherOpen = !launcherOpen; }
    function toggleControlCenter() { controlCenterOpen = !controlCenterOpen; }
    function toggleLogout() { logoutOpen = !logoutOpen; }
    function toggleWallpaperPicker() { wallpaperPickerOpen = !wallpaperPickerOpen; }
    function toggleThemeSwitcher() { themeSwitcherOpen = !themeSwitcherOpen; }
    function toggleSettings() { settingsOpen = !settingsOpen; }
    function toggleCalendar() { calendarOpen = !calendarOpen; }
    function toggleMediaPlayer() { mediaPlayerOpen = !mediaPlayerOpen; }

    // Bar visibility state (hidden by default unless shortcut toggled or OSD/panel requested)
    property bool barVisible: true
    function toggleBar() { barVisible = !barVisible; }
}
