import Foundation
@testable import Shit
import XCTest

final class MeetingDetectorTests: XCTestCase {
    private let detector = MeetingDetector()
    private let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)

    func testFiltersIgnoredEventTypes() {
        let now = referenceDate
        let events: [MeetingEvent] = [
            .fixture(id: "all-day", title: "All Day", startDate: now, isAllDay: true),
            .fixture(id: "free", title: "Free", startDate: now, availability: .free),
            .fixture(id: "declined", title: "Declined", startDate: now, participationStatus: .declined),
            .fixture(id: "canceled", title: "Canceled", startDate: now, status: .canceled),
            .fixture(id: "real", title: "Real Meeting", startDate: now),
        ]

        let filtered = detector.filteredEvents(events: events, filter: MeetingFilterSettings(), now: now)

        XCTAssertEqual(filtered.map(\.id), ["real"])
    }

    func testFiltersExcludedCalendarsAndKeywords() {
        let now = referenceDate
        let events: [MeetingEvent] = [
            .fixture(id: "standup", title: "Standup", calendarID: "work", startDate: now),
            .fixture(id: "hold", title: "Focus Hold", calendarID: "personal", startDate: now),
            .fixture(id: "real", title: "Planning", calendarID: "personal", startDate: now),
        ]
        let filter = MeetingFilterSettings(
            excludedCalendarIdentifiers: ["work"],
            ignoredTitleKeywords: ["hold"]
        )

        let filtered = detector.filteredEvents(events: events, filter: filter, now: now)

        XCTAssertEqual(filtered.map(\.id), ["real"])
    }

    func testIgnoredTitleKeywordsAreTrimmedAndEmptyKeywordsAreIgnored() {
        let now = referenceDate
        let events: [MeetingEvent] = [
            .fixture(id: "hold", title: "Focus Hold", startDate: now),
            .fixture(id: "real", title: "Planning", startDate: now),
        ]
        let filter = MeetingFilterSettings(ignoredTitleKeywords: ["   ", "\n", " hold "])

        let filtered = detector.filteredEvents(events: events, filter: filter, now: now)

        XCTAssertEqual(filtered.map(\.id), ["real"])
    }

    func testReturnsDueOneMinuteAndStartAlerts() {
        let start = referenceDate
        let now = start.addingTimeInterval(-30)
        let event = MeetingEvent.fixture(startDate: start)

        let due = detector.dueAlerts(
            events: [event],
            filter: MeetingFilterSettings(),
            timing: .oneMinuteAndStart,
            now: now
        )

        XCTAssertEqual(due.map(\.offset), [.oneMinuteBefore])
    }

    func testReturnsDueFiveMinuteAlertOnlyWithinLookbackWindow() {
        let start = referenceDate
        let event = MeetingEvent.fixture(startDate: start)

        let tooEarly = detector.dueAlerts(
            events: [event],
            filter: MeetingFilterSettings(),
            timing: .fiveMinutesBefore,
            now: start.addingTimeInterval(-301)
        )
        let due = detector.dueAlerts(
            events: [event],
            filter: MeetingFilterSettings(),
            timing: .fiveMinutesBefore,
            now: start.addingTimeInterval(-290)
        )
        let tooLate = detector.dueAlerts(
            events: [event],
            filter: MeetingFilterSettings(),
            timing: .fiveMinutesBefore,
            now: start.addingTimeInterval(-254)
        )

        XCTAssertTrue(tooEarly.isEmpty)
        XCTAssertEqual(due.map(\.offset), [.fiveMinutesBefore])
        XCTAssertTrue(tooLate.isEmpty)
    }

    func testCurrentActiveMeetingCanTriggerAtStartAfterLaunch() {
        let now = referenceDate
        let start = now.addingTimeInterval(-120)
        let event = MeetingEvent.fixture(startDate: start, endDate: start.addingTimeInterval(1800))

        let due = detector.dueAlerts(
            events: [event],
            filter: MeetingFilterSettings(),
            timing: .atStart,
            now: now
        )

        XCTAssertEqual(due.map(\.offset), [.atStart])
    }

    func testCurrentActiveMeetingDoesNotTriggerAtStartAfterGraceWindow() {
        let now = referenceDate
        let start = now.addingTimeInterval(-16 * 60)
        let event = MeetingEvent.fixture(startDate: start, endDate: now.addingTimeInterval(1800))

        let due = detector.dueAlerts(
            events: [event],
            filter: MeetingFilterSettings(),
            timing: .atStart,
            now: now
        )

        XCTAssertTrue(due.isEmpty)
    }

    func testNextMeetingIgnoresCurrentMeeting() {
        let now = referenceDate
        let current = MeetingEvent.fixture(id: "current", startDate: now.addingTimeInterval(-30))
        let next = MeetingEvent.fixture(id: "next", startDate: now.addingTimeInterval(600))

        XCTAssertEqual(
            detector.currentMeeting(events: [current, next], filter: MeetingFilterSettings(), now: now)?.id,
            "current"
        )
        XCTAssertEqual(
            detector.nextMeeting(events: [current, next], filter: MeetingFilterSettings(), now: now)?.id,
            "next"
        )
    }

    func testMeetingIsNotCurrentAtExactEndDate() {
        let now = referenceDate
        let event = MeetingEvent.fixture(
            id: "done",
            startDate: now.addingTimeInterval(-1800),
            endDate: now
        )

        XCTAssertFalse(event.isActive(at: now))
        XCTAssertNil(detector.currentMeeting(events: [event], filter: MeetingFilterSettings(), now: now))
    }

    func testFilteredEventsSortsByStartDateThenTitle() {
        let now = referenceDate
        let events: [MeetingEvent] = [
            .fixture(id: "same-b", title: "Beta", startDate: now.addingTimeInterval(60)),
            .fixture(id: "later", title: "Later", startDate: now.addingTimeInterval(120)),
            .fixture(id: "same-a", title: "Alpha", startDate: now.addingTimeInterval(60)),
        ]

        let filtered = detector.filteredEvents(events: events, filter: MeetingFilterSettings(), now: now)

        XCTAssertEqual(filtered.map(\.id), ["same-a", "same-b", "later"])
    }
}
