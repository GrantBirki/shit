import AppKit
@testable import Shit
import SwiftUI
import XCTest

@MainActor
final class OverlayWindowTests: XCTestCase {
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

    func testDisplayChangesShowTheCurrentAlertAndRemoveDisconnectedCopies() throws {
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
        try overlay(in: remaining).onDismiss()
        connected = frames
        NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: NSApp)
        XCTAssertTrue(try visibleWindows(on: []).isEmpty)
    }

    private func candidate(_ id: String) -> AlertCandidate {
        AlertCandidate(event: .fixture(id: id, startDate: Date()), offset: .atStart)
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
