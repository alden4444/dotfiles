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
    property bool calendarOpen: false

    // Only ONE panel open at a time. We enforce it here, not at the call sites, so it
    // holds no matter how a panel got opened: a toggle, an IPC open(), or one picker
    // handing off to another. Whenever one flips true, the rest get forced false. Setting
    // a bool that's already false is a no-op, so this never recurses on itself. (polkit
    // isn't a GlobalState panel; the bar already mutes everything else while an auth
    // prompt is up.)
    function keepOnly(which) {
        if (which !== "launcher")  launcherOpen = false;
        if (which !== "cc")        controlCenterOpen = false;
        if (which !== "logout")    logoutOpen = false;
        if (which !== "wallpaper") wallpaperPickerOpen = false;
        if (which !== "theme")     themeSwitcherOpen = false;
        if (which !== "settings")  settingsOpen = false;
        if (which !== "calendar")  calendarOpen = false;
    }
    onLauncherOpenChanged:        if (launcherOpen)         keepOnly("launcher");
    onControlCenterOpenChanged:   if (controlCenterOpen)    keepOnly("cc");
    onLogoutOpenChanged:          if (logoutOpen)           keepOnly("logout");
    onWallpaperPickerOpenChanged: if (wallpaperPickerOpen)  keepOnly("wallpaper");
    onThemeSwitcherOpenChanged:   if (themeSwitcherOpen)    keepOnly("theme");
    onSettingsOpenChanged:        if (settingsOpen)         keepOnly("settings");
    onCalendarOpenChanged:        if (calendarOpen)         keepOnly("calendar");

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
}
