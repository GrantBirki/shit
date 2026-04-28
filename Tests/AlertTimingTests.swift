@testable import Shit
import XCTest

final class AlertTimingTests: XCTestCase {
    func testAlertTimingOffsets() {
        XCTAssertEqual(AlertTiming.atStart.offsets, [.atStart])
        XCTAssertEqual(AlertTiming.oneMinuteBefore.offsets, [.oneMinuteBefore])
        XCTAssertEqual(AlertTiming.fiveMinutesBefore.offsets, [.fiveMinutesBefore])
        XCTAssertEqual(AlertTiming.oneMinuteAndStart.offsets, [.oneMinuteBefore, .atStart])
    }

    func testAlertTimingLabels() {
        XCTAssertEqual(AlertTiming.atStart.label, "At start")
        XCTAssertEqual(AlertTiming.oneMinuteBefore.label, "1 minute before")
        XCTAssertEqual(AlertTiming.fiveMinutesBefore.label, "5 minutes before")
        XCTAssertEqual(AlertTiming.oneMinuteAndStart.label, "1 minute before + at start")
    }

    func testGlassProminenceLabels() {
        XCTAssertEqual(GlassProminence.subtle.label, "Subtle")
        XCTAssertEqual(GlassProminence.balanced.label, "Balanced")
        XCTAssertEqual(GlassProminence.prominent.label, "Prominent")
    }
}
