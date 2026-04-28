import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    private let settings: SettingsStore
    private let authorizationProvider: () -> CalendarAuthorizationState
    private let calendarsProvider: () -> [CalendarSource]
    private let onRequestCalendarAccess: () -> Void
    private let state: SettingsWindowState
    private var onTestAlert: () -> Void
    private var hasCenteredInitialWindow = false

    init(
        settings: SettingsStore,
        authorizationProvider: @escaping () -> CalendarAuthorizationState,
        calendarsProvider: @escaping () -> [CalendarSource],
        onRequestCalendarAccess: @escaping () -> Void,
        onTestAlert: @escaping () -> Void
    ) {
        self.settings = settings
        self.authorizationProvider = authorizationProvider
        self.calendarsProvider = calendarsProvider
        self.onRequestCalendarAccess = onRequestCalendarAccess
        self.onTestAlert = onTestAlert
        state = SettingsWindowState(
            authorization: authorizationProvider(),
            calendars: calendarsProvider()
        )

        let window = NSWindow()
        super.init(window: window)
        configureWindow(window)
        installContent()
    }

    required init?(coder _: NSCoder) {
        nil
    }

    func configureActions(onTestAlert: @escaping () -> Void) {
        self.onTestAlert = onTestAlert
    }

    func show() {
        state.authorization = authorizationProvider()
        state.calendars = calendarsProvider()
        guard let window else { return }
        if !window.isVisible, !hasCenteredInitialWindow {
            if !window.setFrameUsingName("ShitSettingsWindow") {
                window.center()
            }
            hasCenteredInitialWindow = true
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func update(authorization: CalendarAuthorizationState, calendars: [CalendarSource]) {
        state.authorization = authorization
        state.calendars = calendars
    }

    private func configureWindow(_ window: NSWindow) {
        window.title = "Shit Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        window.minSize = NSSize(width: 680, height: 500)
        window.setContentSize(NSSize(width: 720, height: 560))
        window.setFrameAutosaveName("ShitSettingsWindow")
    }

    private func installContent() {
        let view = SettingsView(
            settings: settings,
            state: state,
            onRequestCalendarAccess: onRequestCalendarAccess,
            onOpenCalendarSettings: SystemSettingsOpener.openCalendarPrivacy,
            onTestAlert: { [weak self] in self?.onTestAlert() }
        )
        window?.contentViewController = NSHostingController(rootView: view)
    }
}

@MainActor
final class SettingsWindowState: ObservableObject {
    @Published var authorization: CalendarAuthorizationState
    @Published var calendars: [CalendarSource]

    init(authorization: CalendarAuthorizationState, calendars: [CalendarSource]) {
        self.authorization = authorization
        self.calendars = calendars
    }
}
