import AppKit
import EventKit
@testable import Shit
import XCTest

final class EventKitMappingTests: XCTestCase {
    func testMapsEventKitAvailability() {
        XCTAssertEqual(MeetingAvailability(eventAvailability: .busy), .busy)
        XCTAssertEqual(MeetingAvailability(eventAvailability: .free), .free)
        XCTAssertEqual(MeetingAvailability(eventAvailability: .tentative), .tentative)
        XCTAssertEqual(MeetingAvailability(eventAvailability: .unavailable), .unavailable)
        XCTAssertEqual(MeetingAvailability(eventAvailability: .notSupported), .unknown)
    }

    func testMapsEventKitStatus() {
        XCTAssertEqual(MeetingStatus(eventStatus: .confirmed), .confirmed)
        XCTAssertEqual(MeetingStatus(eventStatus: .tentative), .tentative)
        XCTAssertEqual(MeetingStatus(eventStatus: .canceled), .canceled)
        XCTAssertEqual(MeetingStatus(eventStatus: .none), .unknown)
    }

    func testMapsEventKitParticipationStatus() {
        XCTAssertEqual(MeetingParticipationStatus(eventParticipantStatus: .accepted), .accepted)
        XCTAssertEqual(MeetingParticipationStatus(eventParticipantStatus: .declined), .declined)
        XCTAssertEqual(MeetingParticipationStatus(eventParticipantStatus: .tentative), .tentative)
        XCTAssertEqual(MeetingParticipationStatus(eventParticipantStatus: .pending), .pending)
        XCTAssertEqual(MeetingParticipationStatus(eventParticipantStatus: .delegated), .unknown)
        XCTAssertEqual(MeetingParticipationStatus(eventParticipantStatus: .completed), .unknown)
        XCTAssertEqual(MeetingParticipationStatus(eventParticipantStatus: .inProcess), .unknown)
        XCTAssertEqual(MeetingParticipationStatus(eventParticipantStatus: .unknown), .unknown)
    }

    func testCalendarColorHexConversion() throws {
        let color = try XCTUnwrap(
            NSColor(red: 0.10, green: 0.20, blue: 0.30, alpha: 1).cgColor
        )

        XCTAssertEqual(EventKitCalendarEventProvider.hexColor(color), "#1A334D")
    }
}
