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

        XCTAssertEqual(store.takeNext(from: [candidate], now: now), candidate)
        XCTAssertNil(store.takeNext(from: [candidate], now: now))
    }

    func testDismissedAlertDoesNotPresentAgainUntilExpired() {
        let now = Date()
        let candidate = AlertCandidate(
            event: .fixture(startDate: now, endDate: now.addingTimeInterval(60)),
            offset: .atStart
        )
        var store = AlertStateStore()

        store.dismiss(candidate)

        XCTAssertNil(store.takeNext(from: [candidate], now: now.addingTimeInterval(30)))
        XCTAssertEqual(store.takeNext(from: [candidate], now: now.addingTimeInterval(61)), candidate)
    }

    func testPresentedAlertStateIsPrunedAfterEventEnds() {
        let now = Date()
        let candidate = AlertCandidate(
            event: .fixture(startDate: now, endDate: now.addingTimeInterval(60)),
            offset: .fiveMinutesBefore
        )
        var store = AlertStateStore()

        XCTAssertEqual(store.takeNext(from: [candidate], now: now), candidate)

        XCTAssertNil(store.takeNext(from: [candidate], now: now.addingTimeInterval(30)))
        XCTAssertEqual(store.takeNext(from: [candidate], now: now.addingTimeInterval(61)), candidate)
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

        XCTAssertNil(store.takeNext(from: [first], now: now))
        XCTAssertEqual(store.takeNext(from: [second], now: now), second)
    }

    func testKeepsEachMeetingPendingUntilItCanBeShown() {
        let now = Date()
        let older = AlertCandidate(
            event: .fixture(id: "older", startDate: now.addingTimeInterval(-30)),
            offset: .atStart
        )
        let newer = AlertCandidate(event: .fixture(id: "newer", startDate: now), offset: .atStart)
        var store = AlertStateStore()

        XCTAssertEqual(store.takeNext(from: [older, newer], now: now), older)
        XCTAssertEqual(store.pendingKeys, [newer.key])
        XCTAssertNil(store.takeNext(from: [older, newer], now: now, canPresent: false))
        XCTAssertEqual(store.pendingKeys, [newer.key])
        store.dismiss(older)
        XCTAssertEqual(store.takeNext(from: [older, newer], now: now), newer)
        XCTAssertTrue(store.pendingKeys.isEmpty)
        XCTAssertNil(store.takeNext(from: [older, newer], now: now))
    }
}
