import AppKit
import Combine
import EventKit
import Foundation

@MainActor
final class AppController {
    private let settings: SettingsStore
    private let calendarProvider: CalendarEventProviding
    private let detector: MeetingDetector
    private var alertState = AlertStateStore()
    private let menuBarController: MenuBarController
    private let overlayController = OverlayWindowController()
    private let settingsWindowController: SettingsWindowController
    private let aboutWindowController = AboutWindowController()
    private let launchAtLoginManager = LaunchAtLoginManager()
    private var timer: Timer?
    private var eventStoreObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()
    private var latestEvents: [MeetingEvent] = []
    private var latestAuthorization: CalendarAuthorizationState = .notDetermined
    private var currentCandidate: AlertCandidate?

    init(calendarProvider: CalendarEventProviding = EventKitCalendarEventProvider()) {
        settings = SettingsStore()
        self.calendarProvider = calendarProvider
        detector = MeetingDetector()
        settingsWindowController = SettingsWindowController(
            settings: settings,
            authorizationProvider: { calendarProvider.authorizationState },
            calendarsProvider: { calendarProvider.calendars() },
            onRequestCalendarAccess: {
                Task { @MainActor in
                    _ = await calendarProvider.requestAccess()
                }
            },
            onTestAlert: {}
        )
        menuBarController = MenuBarController(
            onShowCurrentAlert: {},
            onTestAlert: {},
            onCheckNow: {},
            onSettings: {},
            onAbout: {},
            onQuit: {}
        )

        menuBarController.configureActions(
            onShowCurrentAlert: { [weak self] in self?.showCurrentAlert() },
            onTestAlert: { [weak self] in self?.showTestAlert() },
            onCheckNow: { [weak self] in self?.refreshMeetingState() },
            onSettings: { [weak self] in self?.showSettings() },
            onAbout: { [weak self] in self?.aboutWindowController.show() },
            onQuit: { NSApp.terminate(nil) }
        )
        settingsWindowController.configureActions(
            onTestAlert: { [weak self] in self?.showTestAlert() }
        )
    }

    func start() {
        AppLog.app.info("Shit AppController start")
        menuBarController.start()
        observeSettings()
        latestAuthorization = calendarProvider.authorizationState
        updateMenu()
        launchAtLoginManager.setEnabled(settings.autoLaunchEnabled)

        Task {
            await requestCalendarAccessIfNeeded()
            refreshMeetingState()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshMeetingState()
            }
        }

        eventStoreObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshMeetingState()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        overlayController.dismiss()
        if let eventStoreObserver {
            NotificationCenter.default.removeObserver(eventStoreObserver)
        }
    }

    func showSettings() {
        settingsWindowController.show()
    }

    private func observeSettings() {
        settings.$autoLaunchEnabled
            .sink { [weak self] enabled in
                self?.launchAtLoginManager.setEnabled(enabled)
            }
            .store(in: &cancellables)

        let refreshPublishers: [AnyPublisher<Void, Never>] = [
            settings.$alertTiming.map { _ in () }.eraseToAnyPublisher(),
            settings.$ignoreAllDayEvents.map { _ in () }.eraseToAnyPublisher(),
            settings.$ignoreFreeEvents.map { _ in () }.eraseToAnyPublisher(),
            settings.$ignoreDeclinedEvents.map { _ in () }.eraseToAnyPublisher(),
            settings.$excludedCalendarIdentifiers.map { _ in () }.eraseToAnyPublisher(),
            settings.$ignoredTitleKeywordsText.map { _ in () }.eraseToAnyPublisher(),
        ]

        Publishers.MergeMany(refreshPublishers)
            .dropFirst()
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] in self?.refreshMeetingState() }
            .store(in: &cancellables)
    }

    private func requestCalendarAccessIfNeeded() async {
        if calendarProvider.authorizationState == .notDetermined {
            latestAuthorization = await calendarProvider.requestAccess()
        } else {
            latestAuthorization = calendarProvider.authorizationState
        }
        updateMenu()
    }

    private func refreshMeetingState() {
        latestAuthorization = calendarProvider.authorizationState
        guard latestAuthorization.canReadEvents else {
            latestEvents = []
            if !isTestCandidate(currentCandidate) {
                currentCandidate = nil
                overlayController.dismiss()
            }
            updateMenu()
            return
        }

        let now = Date()
        let queryEnd = now.addingTimeInterval(6 * 60 * 60)
        latestEvents = calendarProvider.events(start: now.addingTimeInterval(-15 * 60), end: queryEnd)

        let filter = MeetingFilterSettings(settings: settings)
        let filteredEvents = detector.filteredEvents(events: latestEvents, filter: filter, now: now)
        let candidates = detector.dueAlerts(
            filteredEvents: filteredEvents,
            timing: settings.alertTiming,
            now: now
        )

        if let candidate = candidates.first(where: { alertState.shouldPresent($0, now: now) }) {
            currentCandidate = candidate
            alertState.markPresented(candidate)
            showOverlay(for: candidate)
        } else {
            clearCurrentCandidateIfStale(now: now, filteredEvents: filteredEvents)
        }

        updateMenu()
    }

    private func showOverlay(for candidate: AlertCandidate) {
        overlayController.show(
            candidate: candidate,
            onDismiss: { [weak self] in self?.dismiss(candidate: candidate) }
        )
    }

    private func updateMenu() {
        let now = Date()
        let filter = MeetingFilterSettings(settings: settings)
        let currentCandidateEvent = currentCandidate?.event
        let currentMeeting = if currentCandidateEvent?.isActive(at: now) == true {
            currentCandidateEvent
        } else {
            detector.currentMeeting(events: latestEvents, filter: filter, now: now)
        }
        let nextMeeting = detector.nextMeeting(events: latestEvents, filter: filter, now: now)
        let state = MenuBarState(
            authorization: latestAuthorization,
            currentMeeting: currentMeeting,
            nextMeeting: nextMeeting,
            canShowCurrentAlert: currentCandidate != nil || currentMeeting != nil
        )
        menuBarController.update(state: state)
        settingsWindowController.update(
            authorization: latestAuthorization,
            calendars: calendarProvider.calendars()
        )
    }

    private func showCurrentAlert() {
        if let currentCandidate {
            showOverlay(for: currentCandidate)
            return
        }

        let now = Date()
        let filter = MeetingFilterSettings(settings: settings)
        guard let meeting = detector.currentMeeting(events: latestEvents, filter: filter, now: now) else {
            return
        }
        let candidate = AlertCandidate(event: meeting, offset: .atStart)
        currentCandidate = candidate
        showOverlay(for: candidate)
    }

    private func showTestAlert() {
        let startDate = Date().addingTimeInterval(5 * 60)
        let event = MeetingEvent(
            id: "test-alert-\(UUID().uuidString)",
            calendarID: "test-calendar",
            calendarTitle: "Test Calendar",
            title: "Test Meeting Alert",
            startDate: startDate,
            endDate: startDate.addingTimeInterval(30 * 60)
        )
        let candidate = AlertCandidate(event: event, offset: .fiveMinutesBefore)
        currentCandidate = candidate
        showOverlay(for: candidate)
    }

    private func isTestCandidate(_ candidate: AlertCandidate?) -> Bool {
        guard let candidate else { return false }
        return candidate.event.id.hasPrefix("test-alert-")
            && candidate.event.calendarID == "test-calendar"
    }

    private func clearCurrentCandidateIfStale(now: Date, filteredEvents: [MeetingEvent]) {
        guard let candidate = currentCandidate else { return }
        if now >= candidate.event.endDate {
            currentCandidate = nil
            overlayController.dismiss()
            return
        }
        if isTestCandidate(candidate) {
            return
        }
        let eventStillIncluded = filteredEvents.contains { event in
            event.id == candidate.event.id && event.startDate == candidate.event.startDate
        }
        if !eventStillIncluded {
            currentCandidate = nil
            overlayController.dismiss()
        }
    }

    private func dismiss(candidate: AlertCandidate) {
        alertState.dismiss(candidate)
        if currentCandidate?.key == candidate.key {
            currentCandidate = nil
        }
        overlayController.dismiss()
        updateMenu()
    }
}
