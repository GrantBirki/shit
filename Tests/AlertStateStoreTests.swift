import Foundation
@testable import Shit
import XCTest

final class AlertStateStoreTests: XCTestCase {
    func testPresentedAlertDoesNotPresentAgain() {
        let now = Date()
        let candidate = AlertCandidate(
            event: .fixture(startDate: now, endDate: now.addingTimeInterval(60)),
            offset: .atStart
        )
        var store = AlertStateStore()

        XCTAssertTrue(store.shouldPresent(candidate, now: now))
        store.markPresented(candidate)
        XCTAssertFalse(store.shouldPresent(candidate, now: now))
    }

    func testDismissedAlertDoesNotPresentAgainUntilExpired() {
        let now = Date()
        let candidate = AlertCandidate(
            event: .fixture(startDate: now, endDate: now.addingTimeInterval(60)),
            offset: .atStart
        )
        var store = AlertStateStore()

        store.dismiss(candidate)

        XCTAssertFalse(store.shouldPresent(candidate, now: now.addingTimeInterval(30)))
        XCTAssertTrue(store.shouldPresent(candidate, now: now.addingTimeInterval(61)))
    }

    func testPresentedAlertStateIsPrunedAfterEventEnds() {
        let now = Date()
        let candidate = AlertCandidate(
            event: .fixture(startDate: now, endDate: now.addingTimeInterval(60)),
            offset: .fiveMinutesBefore
        )
        var store = AlertStateStore()

        store.markPresented(candidate)

        XCTAssertFalse(store.shouldPresent(candidate, now: now.addingTimeInterval(30)))
        XCTAssertTrue(store.shouldPresent(candidate, now: now.addingTimeInterval(61)))
    }

    func testDismissingFirstAlertDoesNotSuppressSecondAlert() throws {
        let now = Date()
        let event = MeetingEvent.fixture(startDate: now, endDate: now.addingTimeInterval(60))
        let first = try AlertCandidate(
            event: event,
            offset: XCTUnwrap(AlertOffset(minutesBefore: 30))
        )
        let second = AlertCandidate(event: event, offset: .fiveMinutesBefore)
        var store = AlertStateStore()

        store.dismiss(first)

        XCTAssertFalse(store.shouldPresent(first, now: now))
        XCTAssertTrue(store.shouldPresent(second, now: now))
    }
}
