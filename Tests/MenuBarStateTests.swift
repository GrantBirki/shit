import Foundation
@testable import Shit
import XCTest

final class MenuBarStateTests: XCTestCase {
    private let startDate = Date(timeIntervalSince1970: 1_800_000_000)

    func testMeetingTitleShowsPermissionRecoveryWhenCalendarAccessIsMissing() {
        let state = MenuBarState(
            authorization: .denied,
            currentMeeting: nil,
            nextMeeting: nil,
            canShowCurrentAlert: false
        )

        XCTAssertEqual(state.meetingTitle, "Calendar access needed")
    }

    func testMeetingTitleShowsNoMeetingsWhenCalendarAccessIsGranted() {
        let state = MenuBarState(
            authorization: .authorized,
            currentMeeting: nil,
            nextMeeting: nil,
            canShowCurrentAlert: false
        )

        XCTAssertEqual(state.meetingTitle, "No meetings found")
    }

    func testMeetingTitlePrefersCurrentMeeting() {
        let current = MeetingEvent.fixture(id: "current", title: "Current", startDate: startDate)
        let next = MeetingEvent.fixture(id: "next", title: "Next", startDate: startDate.addingTimeInterval(600))
        let state = MenuBarState(
            authorization: .authorized,
            currentMeeting: current,
            nextMeeting: next,
            canShowCurrentAlert: true
        )

        XCTAssertEqual(state.meetingTitle, "Now: Current")
    }

    func testMeetingTitleShowsNextMeetingTime() {
        let next = MeetingEvent.fixture(id: "next", title: "Planning", startDate: startDate)
        let state = MenuBarState(
            authorization: .authorized,
            currentMeeting: nil,
            nextMeeting: next,
            canShowCurrentAlert: true
        )
        let expectedTime = MeetingDateFormatter.timeOnly.string(from: startDate)

        XCTAssertEqual(state.meetingTitle, "Next: Planning at \(expectedTime)")
    }
}
