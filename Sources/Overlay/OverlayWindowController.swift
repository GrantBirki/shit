import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController {
    private var windows: [NSRect: OverlayWindow] = [:]
    private var lockFocus = false
    private var currentOverlay: MeetingOverlayView?
    private var previousPresentationOptions: NSApplication.PresentationOptions?
    private var presentationDeferred = false
    private let isAppActive: () -> Bool
    private let displayFrames: () -> [NSRect]
    private let openURL: (URL) -> Bool

    init(
        displayFrames: @escaping () -> [NSRect] = { NSScreen.screens.map(\.frame) },
        isAppActive: @escaping () -> Bool = { NSApp.isActive },
        openURL: @escaping (URL) -> Bool = { NSWorkspace.shared.open($0) }
    ) {
        self.displayFrames = displayFrames
        self.openURL = openURL
        self.isAppActive = isAppActive
        NotificationCenter.default.addObserver(
            self, selector: #selector(appBecameActive(_:)),
            name: NSApplication.didBecomeActiveNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(displaysDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification, object: nil
        )
        for name in [NSApplication.didResignActiveNotification, NSWindow.didResignKeyNotification] {
            NotificationCenter.default.addObserver(
                self, selector: #selector(focusDidChange(_:)), name: name, object: nil
            )
        }
    }

    func show(
        candidate: AlertCandidate,
        lockFocus: Bool = false,
        requestFocus: Bool = true,
        onDismiss: @escaping () -> Void
    ) {
        self.lockFocus = lockFocus
        let onOpenMeeting = candidate.event.meetingURL.map { url in
            { [openURL] in
                if openURL(url) {
                    onDismiss()
                }
            }
        }
        let view = MeetingOverlayView(candidate: candidate, onDismiss: onDismiss, onOpenMeeting: onOpenMeeting)
        currentOverlay = view
        present(view, on: displayFrames(), requestFocus: requestFocus)
    }

    @objc private func displaysDidChange(_: Notification) {
        guard let currentOverlay else { return }
        let frames = displayFrames()
        if Set(frames) != Set(windows.keys) {
            present(currentOverlay, on: frames, requestFocus: false)
        }
    }

    @objc private func appBecameActive(_: Notification) {
        guard presentationDeferred, let currentOverlay else { return }
        present(currentOverlay, on: displayFrames(), requestFocus: false)
    }

    private func present(_ view: MeetingOverlayView, on frames: [NSRect], requestFocus: Bool) {
        presentationDeferred = !requestFocus && !lockFocus && !isAppActive()
        for (frame, window) in windows where !frames.contains(frame) {
            window.orderOut(nil)
            windows.removeValue(forKey: frame)
        }
        for frame in frames {
            let window = windows[frame] ?? makeWindow(frame: frame)
            windows[frame] = window
            window.hidesOnDeactivate = !lockFocus
            window.onDismissShortcut = view.onDismiss
            window.contentViewController = NSHostingController(rootView: view)
            window.setFrame(frame, display: !presentationDeferred)
            if !presentationDeferred {
                window.orderFront(nil)
            }
        }
        updatePresentationOptions()
        if !presentationDeferred {
            focusOverlay()
        }
    }

    private func updatePresentationOptions() {
        if windows.isEmpty || !lockFocus {
            if let previousPresentationOptions {
                NSApp.presentationOptions = previousPresentationOptions
                self.previousPresentationOptions = nil
            }
        } else if previousPresentationOptions == nil {
            previousPresentationOptions = NSApp.presentationOptions
            NSApp.presentationOptions = [.hideDock, .hideMenuBar, .disableProcessSwitching, .disableHideApplication]
        }
    }

    @objc private func focusDidChange(_: Notification) {
        guard currentOverlay != nil, lockFocus else { return }
        // Let AppKit finish transferring focus, including between copies of this alert.
        DispatchQueue.main.async { [weak self] in
            guard let self, lockFocus else { return }
            focusOverlay()
        }
    }

    private func focusOverlay() {
        guard let window = windows.values.first(where: \.isKeyWindow)
            ?? NSScreen.main.flatMap({ windows[$0.frame] }) ?? windows.values.first else { return }
        if !NSApp.isActive {
            NSApp.activate(ignoringOtherApps: true)
        }
        if !window.isKeyWindow {
            window.makeKeyAndOrderFront(nil)
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
        presentationDeferred = false
        windows.values.forEach { $0.orderOut(nil) }
        windows.removeAll()
        updatePresentationOptions()
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
