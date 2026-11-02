import AppKit
@testable import Shit
import SwiftUI
import XCTest

@MainActor
final class OverlayWindowTests: XCTestCase {
    func testAppSwitchingStaysDisabledThroughReplacementUntilDismissal() throws {
        let app = NSApplication.shared
        let originalOptions = app.presentationOptions
        app.presentationOptions = [.autoHideDock]
        defer { app.presentationOptions = originalOptions }
        let frames = try twoDisplayFrames()
        let controller = OverlayWindowController(displayFrames: { frames })
        defer { controller.dismiss() }

        controller.show(candidate: candidate("first"), lockFocus: true) { XCTFail("Dismissed the previous alert") }
        XCTAssertTrue(app.presentationOptions.contains(.disableProcessSwitching))
        controller.show(candidate: candidate("second"), lockFocus: true) { controller.dismiss() }
        XCTAssertTrue(app.presentationOptions.contains(.disableProcessSwitching))
        let windows = try visibleWindows(on: frames)
        try overlay(in: XCTUnwrap(windows.last)).onDismiss()
        XCTAssertTrue(windows.allSatisfy { !$0.isVisible })
        XCTAssertEqual(app.presentationOptions, [.autoHideDock])
    }

    func testEscapeDismissesReplacementBeforeTheFocusedViewReceivesIt() throws {
        let frames = try twoDisplayFrames()
        let controller = OverlayWindowController(displayFrames: { frames })
        defer { controller.dismiss() }
        controller.show(candidate: candidate("first")) { XCTFail("Dismissed the previous alert") }
        let firstWindows = try visibleWindows(on: frames)

        var dismissed = false
        controller.show(candidate: candidate("second")) {
            dismissed = true
            controller.dismiss()
        }
        let windows = try visibleWindows(on: frames)
        for (first, replacement) in zip(firstWindows, windows) {
            XCTAssertTrue(first === replacement)
            let view = try overlay(in: replacement)
            XCTAssertEqual(view.candidate.event.id, "second")
        }
        let window = try XCTUnwrap(windows.last)
        window.makeKeyAndOrderFront(nil)
        let responder = KeyConsumingView()
        window.contentView = responder
        XCTAssertTrue(window.makeFirstResponder(responder))
        try window.sendEvent(keyDown("\u{1B}", keyCode: 53, in: window))
        XCTAssertTrue(dismissed)
        XCTAssertFalse(responder.receivedKey)
        XCTAssertTrue(windows.allSatisfy { !$0.isVisible })
    }

    func testJoinShortcutUsesReplacementLinkAndDismissesOnlyOnSuccess() throws {
        let originalOptions = NSApplication.shared.presentationOptions
        let first = try XCTUnwrap(URL(string: "https://example.org/first"))
        let second = try XCTUnwrap(URL(string: "https://example.org/second"))
        var opened: [URL] = []
        var canOpen = false
        let frames = try twoDisplayFrames()
        let controller = OverlayWindowController(displayFrames: { frames }, openURL: { url in
            opened.append(url)
            return canOpen
        })
        defer { controller.dismiss() }
        controller.show(candidate: candidate("first", meetingURL: first)) { XCTFail("Dismissed the previous alert") }
        controller.show(candidate: candidate("second", meetingURL: second)) { controller.dismiss() }
        let windows = try visibleWindows(on: frames)
        let window = try XCTUnwrap(windows.last)
        window.makeKeyAndOrderFront(nil)
        let shortcut = try keyDown("j", keyCode: 38, modifiers: .command, in: window)
        XCTAssertTrue(window.performKeyEquivalent(with: shortcut))
        XCTAssertTrue(window.hidesOnDeactivate)
        XCTAssertEqual(opened, [second])
        XCTAssertTrue(windows.allSatisfy(\.isVisible))
        XCTAssertEqual(NSApp.presentationOptions, originalOptions)
        canOpen = true
        XCTAssertTrue(window.performKeyEquivalent(with: shortcut))
        XCTAssertEqual(opened, [second, second])
        XCTAssertTrue(windows.allSatisfy { !$0.isVisible })
        XCTAssertEqual(NSApp.presentationOptions, originalOptions)
    }

    func testReplacingLinkedMeetingWithLinklessMeetingRemovesJoinActionAndShortcut() throws {
        let url = try XCTUnwrap(URL(string: "https://example.org/meeting"))
        let controller = OverlayWindowController(openURL: { _ in
            XCTFail("Opened a stale link")
            return true
        })
        defer { controller.dismiss() }
        controller.show(candidate: candidate("linked", meetingURL: url)) {}
        controller.show(candidate: candidate("linkless")) {}
        for window in try visibleWindows(on: NSScreen.screens.map(\.frame)) {
            XCTAssertNil(try overlay(in: window).onOpenMeeting)
            let shortcut = try keyDown("j", keyCode: 38, modifiers: .command, in: window)
            XCTAssertFalse(window.performKeyEquivalent(with: shortcut))
        }
    }

    func testCalendarRefreshUpdatesAndRemovesJoinLinkOnEveryVisibleOverlay() throws {
        let original = try XCTUnwrap(URL(string: "https://example.org/original"))
        let updated = try XCTUnwrap(URL(string: "https://example.org/updated"))
        let start = Date().addingTimeInterval(295)
        let calendar = RefreshTestCalendar()
        let frames = try twoDisplayFrames()
        var opened: [URL] = []
        let overlays = OverlayWindowController(displayFrames: { frames }, openURL: { url in
            opened.append(url)
            return false
        })
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let app = AppController(
            calendarProvider: calendar,
            settings: SettingsStore(defaults: defaults),
            overlayController: overlays
        )
        defer { app.stop() }
        calendar.meetings = [.fixture(startDate: start, meetingURL: original)]
        app.refreshMeetingState()
        let windows = try visibleWindows(on: frames)
        for window in windows {
            XCTAssertEqual(try overlay(in: window).candidate.event.meetingURL, original)
        }

        calendar.meetings = [.fixture(startDate: start, meetingURL: updated)]
        app.refreshMeetingState()
        for window in windows {
            XCTAssertTrue(window.isVisible)
            let shortcut = try keyDown("j", keyCode: 38, modifiers: .command, in: window)
            XCTAssertTrue(window.performKeyEquivalent(with: shortcut))
        }
        XCTAssertEqual(opened, [updated, updated])

        calendar.meetings = [.fixture(startDate: start, meetingURL: nil)]
        app.refreshMeetingState()
        for window in windows {
            XCTAssertTrue(window.isVisible)
            XCTAssertNil(try overlay(in: window).onOpenMeeting)
            let shortcut = try keyDown("j", keyCode: 38, modifiers: .command, in: window)
            XCTAssertFalse(window.performKeyEquivalent(with: shortcut))
        }
        XCTAssertEqual(opened, [updated, updated])
    }

    func testDismissShowsNextMeetingWithItsLatestCalendarDetails() throws {
        let calendar = RefreshTestCalendar()
        let frames = try twoDisplayFrames()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let app = AppController(
            calendarProvider: calendar,
            settings: SettingsStore(defaults: defaults),
            overlayController: OverlayWindowController(displayFrames: { frames })
        )
        defer { app.stop() }

        let start = Date().addingTimeInterval(295)
        let first = MeetingEvent.fixture(id: "first", title: "First", startDate: start)
        let second = MeetingEvent.fixture(id: "second", title: "Second", startDate: start)
        calendar.meetings = [second, first]
        app.refreshMeetingState()
        app.refreshMeetingState()
        let firstView = try overlay(in: XCTUnwrap(visibleWindows(on: frames).first))
        XCTAssertEqual(firstView.candidate.event, first)

        let updated = MeetingEvent.fixture(id: "second", title: "Renamed", startDate: start)
        calendar.meetings = [first, updated]
        firstView.onDismiss()
        let nextView = try overlay(in: XCTUnwrap(visibleWindows(on: frames).first))
        XCTAssertEqual(nextView.candidate.event, updated)
        nextView.onDismiss()
        XCTAssertTrue(try visibleWindows(on: []).isEmpty)
    }

    func testDisplayChangesShowTheCurrentAlertAndRemoveDisconnectedCopies() throws {
        let originalOptions = NSApplication.shared.presentationOptions
        let frames = try twoDisplayFrames()
        var connected = [frames[0]]
        let controller = OverlayWindowController(displayFrames: { connected })
        defer { controller.dismiss() }
        controller.show(candidate: candidate("first")) {}
        controller.show(candidate: candidate("current")) { controller.dismiss() }

        connected = frames
        NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: NSApp)
        let windows = try visibleWindows(on: connected)
        for window in windows {
            XCTAssertEqual(try overlay(in: window).candidate.event.id, "current")
        }
        connected = [frames[1]]
        NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: NSApp)
        XCTAssertFalse(windows[0].isVisible)
        let remaining = try XCTUnwrap(visibleWindows(on: connected).first)
        XCTAssertTrue(remaining === windows[1])
        connected = []
        NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: NSApp)
        XCTAssertFalse(remaining.isVisible)
        XCTAssertEqual(NSApp.presentationOptions, originalOptions)
        connected = [frames[0]]
        NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: NSApp)
        let reconnected = try XCTUnwrap(visibleWindows(on: connected).first)
        XCTAssertEqual(NSApp.presentationOptions, originalOptions)
        try overlay(in: reconnected).onDismiss()
        connected = frames
        NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: NSApp)
        XCTAssertTrue(try visibleWindows(on: []).isEmpty)
    }

    func testUnlockedRefreshWaitsUntilTheAppReturnsToTheForeground() throws {
        let frames = try twoDisplayFrames()
        var active = true
        var connected = [frames[0]]
        let controller = OverlayWindowController(displayFrames: { connected }, isAppActive: { active })
        defer { controller.dismiss() }
        controller.show(candidate: candidate("current")) {}
        let window = try XCTUnwrap(visibleWindows(on: connected).first)

        active = false
        window.orderOut(nil)
        controller.show(candidate: candidate("updated"), requestFocus: false) {}
        connected = frames
        NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: NSApp)
        XCTAssertTrue(try visibleWindows(on: []).isEmpty)

        active = true
        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: NSApp)
        for window in try visibleWindows(on: connected) {
            XCTAssertEqual(try overlay(in: window).candidate.event.id, "updated")
        }
    }

    private func candidate(_ id: String, meetingURL: URL? = nil) -> AlertCandidate {
        AlertCandidate(event: .fixture(id: id, startDate: Date(), meetingURL: meetingURL), offset: .atStart)
    }

    private func twoDisplayFrames() throws -> [NSRect] {
        let screen = try XCTUnwrap(NSScreen.main)
        let (left, right) = screen.frame.divided(atDistance: floor(screen.frame.width / 2), from: .minXEdge)
        return [left, right]
    }

    private func overlay(in window: NSWindow) throws -> MeetingOverlayView {
        try XCTUnwrap(window.contentViewController as? NSHostingController<MeetingOverlayView>).rootView
    }

    private func visibleWindows(on frames: [NSRect]) throws -> [NSWindow] {
        let visible = NSApplication.shared.windows.filter { $0.level == .screenSaver && $0.isVisible }
        XCTAssertEqual(visible.count, frames.count)
        return try frames.map { frame in try XCTUnwrap(visible.first { $0.frame == frame }) }
    }

    private func keyDown(
        _ characters: String, keyCode: UInt16, modifiers: NSEvent.ModifierFlags = [], in window: NSWindow
    ) throws -> NSEvent {
        try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: 0,
            windowNumber: window.windowNumber, context: nil, characters: characters,
            charactersIgnoringModifiers: characters, isARepeat: false, keyCode: keyCode
        ))
    }
}

private final class KeyConsumingView: NSView {
    var receivedKey = false
    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with _: NSEvent) {
        receivedKey = true
    }
}

private final class RefreshTestCalendar: CalendarEventProviding {
    let authorizationState = CalendarAuthorizationState.authorized
    var meetings: [MeetingEvent] = []

    func events(start _: Date, end _: Date) -> [MeetingEvent] {
        meetings
    }

    func calendars() -> [CalendarSource] {
        []
    }

    func requestAccess() async -> CalendarAuthorizationState {
        authorizationState
    }
}
