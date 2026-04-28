import Foundation
@testable import Shit
import XCTest

final class OverlayPresentationTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testStatusTextForActiveMeeting() {
        let event = MeetingEvent.fixture(
            startDate: now.addingTimeInterval(-60),
            endDate: now.addingTimeInterval(60)
        )

        XCTAssertEqual(OverlayPresentation.statusText(for: event, now: now), "Meeting is live")
    }

    func testStatusTextForMeetingStartingSoon() {
        let event = MeetingEvent.fixture(startDate: now.addingTimeInterval(45))

        XCTAssertEqual(OverlayPresentation.statusText(for: event, now: now), "Starts in less than a minute")
    }

    func testStatusTextForUpcomingMeeting() {
        let event = MeetingEvent.fixture(startDate: now.addingTimeInterval(5 * 60))

        XCTAssertEqual(OverlayPresentation.statusText(for: event, now: now), "Starts in 5 minutes")
    }
}
