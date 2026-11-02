import AppKit
@testable import Shit
import SwiftUI
import XCTest

@MainActor
final class SettingsTabTests: XCTestCase {
    func testTabNavigationAndTextEditorKeepTheirKeyboardBehavior() throws {
        _ = NSApplication.shared
        let suite = "SettingsTabTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let host = NSHostingView(rootView: SettingsView(
            settings: SettingsStore(defaults: defaults),
            state: SettingsWindowState(authorization: .authorized, calendars: []),
            onRequestCalendarAccess: {},
            onOpenCalendarSettings: {},
            onTestAlert: {}
        ))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 560),
            styleMask: .titled, backing: .buffered, defer: false
        )
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        window.recalculateKeyViewLoop()
        let tabStrip = try XCTUnwrap(host.nextValidKeyView)
        XCTAssertTrue(window.makeFirstResponder(tabStrip))

        func press(_ key: UInt16, _ characters: String, _ modifiers: NSEvent.ModifierFlags) throws {
            let event = try XCTUnwrap(NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: 0,
                windowNumber: window.windowNumber, context: nil, characters: characters,
                charactersIgnoringModifiers: characters, isARepeat: false, keyCode: key
            ))
            if !window.performKeyEquivalent(with: event) {
                window.sendEvent(event)
            }
            host.layoutSubtreeIfNeeded()
        }

        let arrows: NSEvent.ModifierFlags = [.numericPad, .function]
        try press(124, "\u{F703}", arrows)
        XCTAssertNotNil(descendant(of: NSStepper.self, in: host), "Right should select Alerts.")
        try press(123, "\u{F702}", arrows)
        XCTAssertNil(descendant(of: NSStepper.self, in: host))
        XCTAssertNil(descendant(of: NSTextView.self, in: host), "Left should return to General.")
        try press(48, "\t", .control)
        try press(48, "\t", .control)
        let editor = try XCTUnwrap(descendant(of: NSTextView.self, in: host), "Control-Tab should reach Calendars.")
        XCTAssertTrue(window.makeFirstResponder(editor))
        editor.string = "Work"
        editor.setSelectedRange(NSRange(location: 2, length: 0))
        try press(123, "\u{F702}", arrows)
        XCTAssertEqual(editor.selectedRange(), NSRange(location: 1, length: 0))
        XCTAssertTrue(window.firstResponder === editor)
        try press(48, "\u{19}", [.control, .shift])
        XCTAssertNotNil(descendant(of: NSStepper.self, in: host), "Control-Shift-Tab should return to Alerts.")
    }

    private func descendant<T: NSView>(of type: T.Type, in view: NSView) -> T? {
        if let match = view as? T {
            return match
        }
        return view.subviews.lazy.compactMap { self.descendant(of: type, in: $0) }.first
    }
}
