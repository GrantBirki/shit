import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController {
    private var windows: [NSRect: OverlayWindow] = [:]
    private var currentOverlay: MeetingOverlayView?
    private let displayFrames: () -> [NSRect]

    init(displayFrames: @escaping () -> [NSRect] = { NSScreen.screens.map(\.frame) }) {
        self.displayFrames = displayFrames
        NotificationCenter.default.addObserver(
            self, selector: #selector(displaysDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification, object: nil
        )
    }

    func show(candidate: AlertCandidate, onDismiss: @escaping () -> Void) {
        let view = MeetingOverlayView(candidate: candidate, onDismiss: onDismiss)
        currentOverlay = view
        present(view, on: displayFrames(), focus: true)
    }

    @objc private func displaysDidChange(_: Notification) {
        guard let currentOverlay else { return }
        let frames = displayFrames()
        if Set(frames) != Set(windows.keys) {
            let hasFocus = windows.isEmpty || windows.values.contains(where: \.isKeyWindow)
            present(currentOverlay, on: frames, focus: hasFocus)
        }
    }

    private func present(_ view: MeetingOverlayView, on frames: [NSRect], focus: Bool) {
        let activeDisplay = NSScreen.main?.frame
        for (frame, window) in windows where !frames.contains(frame) {
            window.orderOut(nil)
            windows.removeValue(forKey: frame)
        }
        for frame in frames {
            let window = windows[frame] ?? makeWindow(frame: frame)
            windows[frame] = window
            window.onDismissShortcut = view.onDismiss
            window.contentViewController = NSHostingController(rootView: view)
            window.setFrame(frame, display: true)
            window.orderFront(nil)
        }
        if focus, let keyWindow = activeDisplay.flatMap({ windows[$0] }) ?? windows.values.first {
            NSApp.activate(ignoringOtherApps: true)
            keyWindow.makeKeyAndOrderFront(nil)
        }
    }

    private func makeWindow(frame: NSRect) -> OverlayWindow {
        let window = OverlayWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        return window
    }

    func dismiss() {
        currentOverlay = nil
        windows.values.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }
}

enum OverlayKeyboard {
    private static let escapeKeyCode: UInt16 = 53
    private static let escapeCharacter = "\u{1B}"

    static func isEscapeKey(keyCode: UInt16, charactersIgnoringModifiers: String?) -> Bool {
        keyCode == escapeKeyCode || charactersIgnoringModifiers == escapeCharacter
    }
}

private extension NSEvent {
    var isOverlayDismissShortcut: Bool {
        OverlayKeyboard.isEscapeKey(
            keyCode: keyCode,
            charactersIgnoringModifiers: charactersIgnoringModifiers
        )
    }
}

@MainActor
private final class OverlayWindow: NSWindow {
    var onDismissShortcut: (() -> Void)?

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func sendEvent(_ event: NSEvent) {
        guard event.type == .keyDown, event.isOverlayDismissShortcut else {
            super.sendEvent(event)
            return
        }

        onDismissShortcut?()
    }

    override func cancelOperation(_ sender: Any?) {
        guard let onDismissShortcut else {
            super.cancelOperation(sender)
            return
        }

        onDismissShortcut()
    }
}
