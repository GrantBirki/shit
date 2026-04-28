import EventKit
@testable import Shit
import XCTest

final class CalendarAuthorizationStateTests: XCTestCase {
    func testMapsEventKitAuthorizationStates() {
        XCTAssertEqual(CalendarAuthorizationState(status: .notDetermined), .notDetermined)
        XCTAssertEqual(CalendarAuthorizationState(status: .fullAccess), .authorized)
        XCTAssertEqual(CalendarAuthorizationState(status: .denied), .denied)
        XCTAssertEqual(CalendarAuthorizationState(status: .restricted), .restricted)
        XCTAssertEqual(CalendarAuthorizationState(status: .writeOnly), .writeOnly)
    }

    func testOnlyFullAccessCanReadEvents() {
        XCTAssertTrue(CalendarAuthorizationState.authorized.canReadEvents)
        XCTAssertFalse(CalendarAuthorizationState.notDetermined.canReadEvents)
        XCTAssertFalse(CalendarAuthorizationState.denied.canReadEvents)
        XCTAssertFalse(CalendarAuthorizationState.restricted.canReadEvents)
        XCTAssertFalse(CalendarAuthorizationState.writeOnly.canReadEvents)
        XCTAssertFalse(CalendarAuthorizationState.unknown.canReadEvents)
    }

    func testMenuTitlesAreHumanReadable() {
        XCTAssertEqual(CalendarAuthorizationState.notDetermined.menuTitle, "Calendar access not requested")
        XCTAssertEqual(CalendarAuthorizationState.authorized.menuTitle, "Calendar access granted")
        XCTAssertEqual(CalendarAuthorizationState.denied.menuTitle, "Calendar access denied")
        XCTAssertEqual(CalendarAuthorizationState.restricted.menuTitle, "Calendar access restricted")
        XCTAssertEqual(CalendarAuthorizationState.writeOnly.menuTitle, "Calendar access is write-only")
        XCTAssertEqual(CalendarAuthorizationState.unknown.menuTitle, "Calendar access unknown")
    }
}
