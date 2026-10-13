#!/usr/bin/env python3
"""
Shark Hot-Reload Watcher
Monitors `Sources/` for Swift changes, triggers incremental compilation,
updates Shark.app, and reloads the running application.
"""

import os
import sys
import time
import subprocess
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SOURCES_DIR = PROJECT_ROOT / "Sources"
APP_BUNDLE_EXEC = PROJECT_ROOT / "Shark.app" / "Contents" / "MacOS" / "Shark"
BUILT_EXEC = PROJECT_ROOT / ".build" / "out" / "Products" / "Debug" / "Shark"

def get_file_mtimes():
    mtimes = {}
    for root, _, files in os.walk(SOURCES_DIR):
        for f in files:
            if f.endswith(".swift"):
                p = os.path.join(root, f)
                try:
                    mtimes[p] = os.path.getmtime(p)
                except OSError:
                    pass
    return mtimes

def build():
    print("\n⚡️ Changes detected, compiling...", flush=True)
    t0 = time.time()
    res = subprocess.run(["swift", "build"], cwd=PROJECT_ROOT)
    if res.returncode == 0:
        elapsed = time.time() - t0
        print(f"✅ Build succeeded in {elapsed:.2f}s", flush=True)
        # Update App Bundle
        if BUILT_EXEC.exists() and APP_BUNDLE_EXEC.parent.exists():
            subprocess.run(["cp", str(BUILT_EXEC), str(APP_BUNDLE_EXEC)], check=False)
        return True
    else:
        print("❌ Build failed. Waiting for next save...", flush=True)
        return False

def restart_app():
    print("🔄 Relaunching Shark.app...", flush=True)
    subprocess.run(["killall", "Shark"], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
    time.sleep(0.4)
    subprocess.run(["open", str(PROJECT_ROOT / "Shark.app")])

def main():
    print("🔥 Shark Hot Reload active! Watching Sources/ for changes...", flush=True)
    print("Press Ctrl+C to stop.")
    
    # Initial build and run
    if build():
        restart_app()

    last_mtimes = get_file_mtimes()

    while True:
        time.sleep(0.5)
        current_mtimes = get_file_mtimes()

        changed = False
        for path, mtime in current_mtimes.items():
            if path not in last_mtimes or mtime > last_mtimes[path]:
                changed = True
                break

        if not changed and len(current_mtimes) != len(last_mtimes):
            changed = True

        if changed:
            last_mtimes = current_mtimes
            if build():
                restart_app()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n👋 Stopped Shark hot reload.")
        sys.exit(0)
