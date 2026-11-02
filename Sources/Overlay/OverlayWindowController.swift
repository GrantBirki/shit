import Accessibility
import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController {
    private var windows: [NSRect: OverlayWindow] = [:]
    private var lockFocus = false
    private var currentOverlay: MeetingOverlayView?
    private var previousPresentationOptions: NSApplication.PresentationOptions?
    private var presentationDeferred = false
    private var awaitingFirstDisplay = false

    var hasHiddenReminder: Bool {
        !lockFocus && !isAppActive() && !windows.isEmpty && !windows.values.contains(where: \.isVisible)
    }

    private let isAppActive: () -> Bool
    private let displayFrames: () -> [NSRect]
    private let openURL: (URL) -> Bool
    private let linkRecovery: MeetingLinkRecovery
    private let announceLinkFailure: () -> Void

    init(
        displayFrames: @escaping () -> [NSRect] = { NSScreen.screens.map(\.frame) },
        isAppActive: @escaping () -> Bool = { NSApp.isActive },
        openURL: @escaping (URL) -> Bool = { NSWorkspace.shared.open($0) },
        copyURL: @escaping (URL) -> Void = { url in
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(url.absoluteString, forType: .string)
        },
        announceLinkFailure: @escaping () -> Void = {
            AccessibilityNotification.Announcement("Couldn't open the meeting link. Copy Link is available.").post()
        }
    ) {
        self.displayFrames = displayFrames
        self.openURL = openURL
        linkRecovery = MeetingLinkRecovery(copyURL: copyURL)
        self.announceLinkFailure = announceLinkFailure
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
        onJoined: (() -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.lockFocus = lockFocus
        if !hasCurrentLink(for: candidate) {
            linkRecovery.failedURL = nil
        }
        let onOpenMeeting = candidate.event.meetingURL.map { url in
            { [weak self] in
                guard let self, hasCurrentLink(for: candidate) else { return }
                if openURL(url) {
                    linkRecovery.failedURL = nil
                    (onJoined ?? onDismiss)()
                } else if linkRecovery.failedURL != url {
                    linkRecovery.failedURL = url
                    announceLinkFailure()
                }
            }
        }
        let view = MeetingOverlayView(
            candidate: candidate, onDismiss: onDismiss, onOpenMeeting: onOpenMeeting, linkRecovery: linkRecovery
        )
        currentOverlay = view
        present(view, on: displayFrames(), requestFocus: requestFocus)
    }

    private func hasCurrentLink(for candidate: AlertCandidate) -> Bool {
        guard let current = currentOverlay?.candidate else { return false }
        return current.key == candidate.key && current.event.meetingURL == candidate.event.meetingURL
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
        if requestFocus {
            awaitingFirstDisplay = frames.isEmpty
        }
        presentationDeferred = !requestFocus && !awaitingFirstDisplay && !lockFocus && !isAppActive()
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
        if !frames.isEmpty, !presentationDeferred {
            awaitingFirstDisplay = false
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
        linkRecovery.failedURL = nil
        awaitingFirstDisplay = false
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
