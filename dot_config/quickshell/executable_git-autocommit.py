#!/usr/bin/env python3
import os
import sys
import time
import subprocess
from pathlib import Path

REPO_PATH = Path("/home/alden/.config/quickshell").resolve()
DEBOUNCE_SECONDS = 3.0
CHECK_INTERVAL_SECONDS = 1.0

def run_git_command(args):
    try:
        res = subprocess.run(
            ["git"] + args,
            cwd=REPO_PATH,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        return res.returncode, res.stdout.strip(), res.stderr.strip()
    except Exception as e:
        return -1, "", str(e)

def has_changes():
    code, stdout, _ = run_git_command(["status", "--porcelain"])
    return code == 0 and len(stdout) > 0

def auto_commit_and_push():
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] Changes detected. Preparing to commit...")

    # Stage all changes
    code, _, err = run_git_command(["add", "-A"])
    if code != 0:
        print(f"Error staging files: {err}")
        return

    # Commit
    commit_msg = f"Auto-save: {timestamp}"
    code, out, err = run_git_command(["commit", "-m", commit_msg])
    if code != 0:
        print(f"Error committing: {err}")
        return
    print(f"Committed: {commit_msg}")

    # Push to origin main
    code, out, err = run_git_command(["push", "origin", "main"])
    if code == 0:
        print(f"Successfully pushed to GitHub!")
    else:
        print(f"Push failed (will retry on next change/save): {err}")

def main():
    print(f"Starting Quickshell Git Auto-Commit watcher for {REPO_PATH}...")
    pending_change_time = None

    while True:
        try:
            if has_changes():
                if pending_change_time is None:
                    pending_change_time = time.time()
                elif time.time() - pending_change_time >= DEBOUNCE_SECONDS:
                    auto_commit_and_push()
                    pending_change_time = None
            else:
                pending_change_time = None

            time.sleep(CHECK_INTERVAL_SECONDS)
        except KeyboardInterrupt:
            print("Stopping watcher...")
            sys.exit(0)
        except Exception as e:
            print(f"Unexpected error: {e}")
            time.sleep(5)

if __name__ == "__main__":
    main()
