import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController {
    private var windows: [NSWindow] = []

    func show(
        candidate: AlertCandidate,
        onDismiss: @escaping () -> Void
    ) {
        dismiss()

        windows = NSScreen.screens.map { screen in
            let view = MeetingOverlayView(
                candidate: candidate,
                onDismiss: onDismiss
            )
            let hostingController = NSHostingController(rootView: view)
            hostingController.view.frame = NSRect(origin: .zero, size: screen.frame.size)
            hostingController.view.autoresizingMask = [.width, .height]
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.contentViewController = hostingController
            window.setFrame(screen.frame, display: true)
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.ignoresMouseEvents = false
            window.makeKeyAndOrderFront(nil)
            return window
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    func dismiss() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }
}
