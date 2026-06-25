pragma Singleton
import Quickshell
import Quickshell.Services.Pam

// Lock state + PAM auth, kept in a singleton 'cause the per-screen
// WlSessionLockSurface is its own isolated scope and can't see ids, only this.
// Exactly ONE thing clears `locked`: PamResult.Success. Every failure or error
// stays locked, no exceptions (fail closed). Password's never stored, logged, or
// echoed. Ever.
Singleton {
    id: root

    property bool locked: false
    property string errorMsg: ""
    property bool authenticating: false
    readonly property bool prompting: pam.responseRequired
    readonly property string message: pam.message

    function lock() {
        if (locked)
            return;
        errorMsg = "";
        authenticating = false;
        locked = true;
        pam.start();
    }

    function submit(pw) {
        if (!pam.responseRequired || authenticating || pw.length === 0)
            return;
        errorMsg = "";
        authenticating = true;
        pam.respond(pw);
    }

    PamContext {
        id: pam
        // config is "su", NOT "login". Read this before you "fix" it: on this box
        // "login" (pam_unix with try_first_pass nullok + faillock) straight up ACCEPTED
        // a wrong password through Quickshell's conversation. As in it failed OPEN. Yeah.
        // "su" (plain pam_unix) rejects it like it should. Do NOT switch it back, and
        // re-test a wrong password after touching anything PAM. I'm serious.
        config: "su"

        onCompleted: result => {
            root.authenticating = false;
            if (result === PamResult.Success) {
                root.locked = false; // the one and only way out
            } else {
                root.errorMsg = result === PamResult.MaxTries ? "Too many attempts"
                              : result === PamResult.Error ? "Authentication error"
                              : "Incorrect password";
                pam.start(); // fresh prompt, still locked
            }
        }
        onError: root.errorMsg = "Authentication error"
    }
}
