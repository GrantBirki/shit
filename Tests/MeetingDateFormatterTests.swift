import Foundation
@testable import Shit
import XCTest

final class MeetingDateFormatterTests: XCTestCase {
    func testMeetingLabelsFollowSystemTimeZoneChanges() throws {
        // Change only this test process's timezone, leaving macOS settings alone.
        let originalTimeZone = ProcessInfo.processInfo.environment["TZ"]
        defer {
            if let originalTimeZone {
                setenv("TZ", originalTimeZone, 1)
            } else {
                unsetenv("TZ")
            }
            NSTimeZone.resetSystemTimeZone()
        }

        let event = MeetingEvent.fixture(startDate: Date(timeIntervalSince1970: 1_800_000_000))
        let state = MenuBarState(
            authorization: .authorized,
            currentMeeting: nil,
            nextMeeting: event,
            canShowCurrentAlert: false
        )

        for identifier in ["Europe/London", "Asia/Tokyo", "Pacific/Honolulu"] {
            let timeZone = try XCTUnwrap(TimeZone(identifier: identifier))
            setenv("TZ", identifier, 1)
            NSTimeZone.resetSystemTimeZone()
            XCTAssertEqual(TimeZone.current.identifier, identifier)

            let expectedTime = DateFormatter()
            expectedTime.timeStyle = .short
            expectedTime.dateStyle = .none
            expectedTime.timeZone = timeZone
            let expectedInterval = DateIntervalFormatter()
            expectedInterval.timeStyle = .short
            expectedInterval.dateStyle = .none
            expectedInterval.timeZone = timeZone

            XCTAssertEqual(
                state.meetingTitle,
                "Next: \(event.title) at \(expectedTime.string(from: event.startDate))",
                identifier
            )
            XCTAssertEqual(
                event.timeRangeLabel,
                expectedInterval.string(from: event.startDate, to: event.endDate),
                identifier
            )
        }
    }
}
