import AppKit

/// Mouse side buttons: back/forward through folder history, or ⌃ + side button to switch tabs.
@MainActor
enum SideButtonNavigation {
    private static var monitor: Any?

    static func install(workspace: WorkspaceState) {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .otherMouseUp) { event in
            // Buttons 0-2 are left/right/middle; 3 is "back" and 4 is "forward" on side-button mice.
            guard MouseSetting.sideButtons.isEnabled, event.window != nil,
                  event.buttonNumber == 3 || event.buttonNumber == 4 else { return event }
            let isBack = event.buttonNumber == 3
            MainActor.assumeIsolated {
                if event.modifierFlags.contains(.control) {
                    isBack ? workspace.previousTab() : workspace.nextTab()
                } else if isBack {
                    workspace.activeNavigationState.goBack()
                } else {
                    workspace.activeNavigationState.goForward()
                }
            }
            return nil
        }
    }
}
