import AppKit

struct MenuBarState: Equatable {
    var authorization: CalendarAuthorizationState
    var currentMeeting: MeetingEvent?
    var nextMeeting: MeetingEvent?
    var canShowCurrentAlert: Bool

    var meetingTitle: String {
        if let currentMeeting {
            return "Now: \(currentMeeting.title)"
        }
        if let nextMeeting {
            return "Next: \(nextMeeting.title) at \(MeetingDateFormatter.timeOnly.string(from: nextMeeting.startDate))"
        }
        if authorization.canReadEvents {
            return "No meetings found"
        }
        return "Calendar access needed"
    }
}

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let statusItemView = NSMenuItem(title: "Starting...", action: nil, keyEquivalent: "")
    private let meetingItem = NSMenuItem(title: "No meetings found", action: nil, keyEquivalent: "")
    private let showAlertItem = NSMenuItem(
        title: "Show Current Alert",
        action: #selector(showCurrentAlert),
        keyEquivalent: ""
    )
    private let testAlertItem = NSMenuItem(title: "Test Alert", action: #selector(testAlert), keyEquivalent: "t")
    private let checkNowItem = NSMenuItem(title: "Check Now", action: #selector(checkNow), keyEquivalent: "r")
    private let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
    private let aboutItem = NSMenuItem(title: "About Shit", action: #selector(openAbout), keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "Quit Shit", action: #selector(quit), keyEquivalent: "q")
    private var state = MenuBarState(
        authorization: .notDetermined,
        currentMeeting: nil,
        nextMeeting: nil,
        canShowCurrentAlert: false
    )

    private var onShowCurrentAlert: () -> Void
    private var onTestAlert: () -> Void
    private var onCheckNow: () -> Void
    private var onSettings: () -> Void
    private var onAbout: () -> Void
    private var onQuit: () -> Void

    init(
        onShowCurrentAlert: @escaping () -> Void,
        onTestAlert: @escaping () -> Void,
        onCheckNow: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        onAbout: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onShowCurrentAlert = onShowCurrentAlert
        self.onTestAlert = onTestAlert
        self.onCheckNow = onCheckNow
        self.onSettings = onSettings
        self.onAbout = onAbout
        self.onQuit = onQuit
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        for item in [showAlertItem, testAlertItem, checkNowItem, settingsItem, aboutItem, quitItem] {
            item.target = self
        }
    }

    func configureActions(
        onShowCurrentAlert: @escaping () -> Void,
        onTestAlert: @escaping () -> Void,
        onCheckNow: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        onAbout: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onShowCurrentAlert = onShowCurrentAlert
        self.onTestAlert = onTestAlert
        self.onCheckNow = onCheckNow
        self.onSettings = onSettings
        self.onAbout = onAbout
        self.onQuit = onQuit
    }

    func start() {
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "calendar.badge.clock", accessibilityDescription: "Shit") {
                button.image = image
                button.imagePosition = .imageOnly
            } else {
                button.title = "Shit"
            }
        }

        statusItemView.isEnabled = false
        meetingItem.isEnabled = false
        menu.delegate = self
        menu.addItem(statusItemView)
        menu.addItem(meetingItem)
        menu.addItem(.separator())
        menu.addItem(showAlertItem)
        menu.addItem(testAlertItem)
        menu.addItem(checkNowItem)
        menu.addItem(.separator())
        menu.addItem(settingsItem)
        menu.addItem(aboutItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
        statusItem.menu = menu
        refresh()
    }

    func update(state: MenuBarState) {
        self.state = state
        refresh()
    }

    func menuNeedsUpdate(_: NSMenu) {
        refresh()
    }

    private func refresh() {
        statusItemView.title = state.authorization.menuTitle
        meetingItem.title = state.meetingTitle
        showAlertItem.isEnabled = state.canShowCurrentAlert
        checkNowItem.isEnabled = state.authorization.canReadEvents
        if let button = statusItem.button {
            button.toolTip = state.meetingTitle
        }
    }

    @objc private func showCurrentAlert() {
        onShowCurrentAlert()
    }

    @objc private func testAlert() {
        onTestAlert()
    }

    @objc private func checkNow() {
        onCheckNow()
    }

    @objc private func openSettings() {
        onSettings()
    }

    @objc private func openAbout() {
        onAbout()
    }

    @objc private func quit() {
        onQuit()
    }
}
