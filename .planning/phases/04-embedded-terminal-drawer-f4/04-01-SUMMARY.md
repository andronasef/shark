# Plan 04-01 Summary: Embedded Terminal Drawer (F4)

## Completed Objectives

- Built `PTYSession` managing master/slave pseudo-terminal descriptors (`openpty`), executing `$SHELL` (zsh) with non-blocking GCD `readabilityHandler` and robust lifecycle management (`SIGKILL` child cleanup).
- Implemented `TerminalNSView` AppKit custom `NSTextView` with dark terminal styling, SF Mono monospace typography, and keyboard interception forwarding raw keystrokes and ANSI escape codes to the PTY.
- Wrapped into SwiftUI `TerminalView` and built `TerminalDrawerContainerView` with drag resize handle (120pt to 500pt), working directory badge, buffer clear, and close buttons.
- Integrated terminal drawer into `ContentView`:
  - Toggle button in toolbar with `terminal.fill` icon.
  - Keyboard shortcut `F4` / `⌥⌘T`.
  - Automatic directory tracking: changes in active pane's directory automatically trigger `syncDirectory(to:)` (`cd "<path>"`).
- Added comprehensive unit tests in `TerminalTests` verifying initial state, buffer clear, directory synchronization, shell spawn, and safe termination — all 4 tests passing.

## Verification

- `swift build` compiled successfully in 0.49s.
- `swift test` passed all 21 unit tests:
  - `FileSystemServiceTests`: 5 passed
  - `NavigationStateTests`: 4 passed
  - `SortingFilteringTests`: 4 passed
  - `TerminalTests`: 4 passed
  - `WorkspaceStateTests`: 4 passed

## Requirements Satisfied

- TERM-01: User can toggle the embedded bottom terminal drawer (`F4`).
- TERM-02: Terminal runs an interactive pseudo-terminal (PTY) with the user's login shell ($SHELL, e.g. zsh).
- TERM-03: Terminal tracks the active pane's working directory upon pane change or file navigation.
