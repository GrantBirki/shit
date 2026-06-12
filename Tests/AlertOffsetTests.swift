@testable import Shit
import XCTest

final class AlertOffsetTests: XCTestCase {
    func testSupportedRange() {
        XCTAssertEqual(AlertOffset(minutesBefore: 0), .atStart)
        XCTAssertEqual(AlertOffset(minutesBefore: 1), .oneMinuteBefore)
        XCTAssertEqual(AlertOffset(minutesBefore: 5), .fiveMinutesBefore)
        XCTAssertEqual(AlertOffset(minutesBefore: 120)?.minutesBefore, 120)
        XCTAssertNil(AlertOffset(minutesBefore: -1))
        XCTAssertNil(AlertOffset(minutesBefore: 121))
    }

    func testLabels() {
        XCTAssertEqual(AlertOffset.atStart.label, "At start")
        XCTAssertEqual(AlertOffset.oneMinuteBefore.label, "1 minute before")
        XCTAssertEqual(AlertOffset.fiveMinutesBefore.label, "5 minutes before")
        XCTAssertEqual(AlertOffset(minutesBefore: 30)?.label, "30 minutes before")
    }

    func testTimeIntervals() {
        XCTAssertEqual(AlertOffset.atStart.timeInterval, 0)
        XCTAssertEqual(AlertOffset.oneMinuteBefore.timeInterval, -60)
        XCTAssertEqual(AlertOffset(minutesBefore: 30)?.timeInterval, -1800)
    }

    func testOffsetParticipatesInAlertIdentityAndTriggerDate() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let event = MeetingEvent.fixture(startDate: start)
        let early = try AlertCandidate(
            event: event,
            offset: XCTUnwrap(AlertOffset(minutesBefore: 30))
        )
        let late = AlertCandidate(event: event, offset: .fiveMinutesBefore)

        XCTAssertNotEqual(early.key, late.key)
        XCTAssertEqual(early.triggerDate, start.addingTimeInterval(-1800))
        XCTAssertEqual(late.triggerDate, start.addingTimeInterval(-300))
    }

    func testGlassProminenceLabels() {
        XCTAssertEqual(GlassProminence.subtle.label, "Subtle")
        XCTAssertEqual(GlassProminence.balanced.label, "Balanced")
        XCTAssertEqual(GlassProminence.prominent.label, "Prominent")
    }
}
