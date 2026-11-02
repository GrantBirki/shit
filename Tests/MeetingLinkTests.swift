import Foundation
@testable import Shit
import XCTest

final class MeetingLinkTests: XCTestCase {
    func testUsesEventURLOrLocationForCustomMeetingService() throws {
        let link = try XCTUnwrap(URL(string: "https://video.example.org/room/123"))
        XCTAssertEqual(MeetingLink.resolve(url: link, location: nil, notes: nil), link)
        XCTAssertEqual(MeetingLink.resolve(url: nil, location: link.absoluteString, notes: nil), link)
    }

    func testCustomLinkEmbeddedInLocationWinsOverCalendarEntry() throws {
        let link = try XCTUnwrap(URL(string: "https://video.example.org/room/123"))
        let location = "Video room: " + link.absoluteString
        for entry in ["https://calendar.example.org/event", "https://www.google.com/calendar/event?eid=123"] {
            let url = try XCTUnwrap(URL(string: entry))
            XCTAssertEqual(MeetingLink.resolve(url: url, location: location, notes: nil), link)
        }
        XCTAssertNil(MeetingLink.resolve(url: nil, location: nil, notes: "Agenda: " + link.absoluteString))
    }

    func testDirectionsDoNotReplaceACustomMeetingURL() throws {
        let meeting = try XCTUnwrap(URL(string: "https://video.example.org/room/123"))
        for location in ["https://maps.apple.com/?q=HQ", "Directions: https://maps.apple.com/?q=HQ"] {
            XCTAssertEqual(MeetingLink.resolve(url: meeting, location: location, notes: nil), meeting)
        }
    }

    func testPrefersConferenceLinkToCalendarEntryAndAgenda() throws {
        let entry = try XCTUnwrap(URL(string: "https://calendar.google.com/calendar/event?id=123"))
        let notes = "Agenda: https://example.org/doc. Join: https://example.zoom.us/j/123?pwd=abc"
        XCTAssertEqual(
            MeetingLink.resolve(url: entry, location: "Conference room", notes: notes)?.absoluteString,
            "https://example.zoom.us/j/123?pwd=abc"
        )
    }

    func testPrefersConferenceInLocationToLinkInNotes() {
        XCTAssertEqual(
            MeetingLink.resolve(
                url: nil, location: "Join at https://meet.google.com/abc-defg-hij",
                notes: "Backup: https://teams.microsoft.com/meet/123"
            )?.absoluteString, "https://meet.google.com/abc-defg-hij"
        )
    }

    func testRejectsUnsafeURLsUnrelatedNotesAndLookalikeHosts() {
        let notes = "See https://example.org/agenda or https://zoom.us.example.org/j/123"
        XCTAssertNil(MeetingLink.resolve(url: URL(string: "file:///tmp/meeting"), location: "Room 2", notes: notes))
        XCTAssertNil(MeetingLink.resolve(url: nil, location: nil, notes: nil))
    }
}
