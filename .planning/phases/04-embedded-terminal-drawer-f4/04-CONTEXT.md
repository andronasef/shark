# Phase 4: Embedded Terminal Drawer (F4) - Context

**Gathered:** 2026-10-13
**Status:** Ready for planning
**Mode:** Autonomous (Dolphin F4 Embedded Terminal Drawer)

<domain>
## Phase Boundary

Implement KDE Dolphin's signature power-user feature: The F4 bottom terminal panel.
1. Interactive pseudo-terminal (PTY) session spawning user's default login shell ($SHELL, zsh).
2. Live terminal drawer with smooth slide-up/down collapse toggled via F4 / toolbar / shortcut.
3. Bidirectional directory sync: when active pane directory changes, the terminal syncs working directory.

Requirements covered: TERM-01, TERM-02, TERM-03.
</domain>

<decisions>
## Implementation Decisions

### 1. Pseudo-Terminal (PTY) Engine
- `PTYSession`: Uses POSIX `openpty()` to obtain master and slave file descriptors.
- Sets slave window size (`winsize` via `ioctl(TIOCSWINSZ)`).
- Spawns `$SHELL` (or `/bin/zsh`) in non-blocking background task.
- Captures output asynchronously using `FileHandle` read stream and dispatches updates to terminal buffer.
- Sends user keystrokes into master file descriptor.

### 2. Terminal UI (AppKit NSTextView Bridge)
- `TerminalTextView`: Customized AppKit `NSTextView` styled with monospace SF Mono / Menlo font, dark terminal theme, blinking cursor, and direct key event handling.
- Bridged to SwiftUI via `NSViewRepresentable` (`TerminalView`).
- Resizable bottom drawer container with grab handle and close/clear buttons.

### 3. Active Directory Synchronization (Dolphin F4 behavior)
- When user navigates to a new directory in the active pane, `WorkspaceState` notifies the active `PTYSession` to sync (`cd "<path>"`).
- Toggle F4 preserves the running shell session across hide/show.

</decisions>
