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

        XCTAssertEqual(store.takeLatest(from: [candidate], now: now), candidate)
        XCTAssertNil(store.takeLatest(from: [candidate], now: now))
    }

    func testDismissedAlertDoesNotPresentAgainUntilExpired() {
        let now = Date()
        let candidate = AlertCandidate(
            event: .fixture(startDate: now, endDate: now.addingTimeInterval(60)),
            offset: .atStart
        )
        var store = AlertStateStore()

        store.dismiss(candidate)

        XCTAssertNil(store.takeLatest(from: [candidate], now: now.addingTimeInterval(30)))
        XCTAssertEqual(store.takeLatest(from: [candidate], now: now.addingTimeInterval(61)), candidate)
    }

    func testPresentedAlertStateIsPrunedAfterEventEnds() {
        let now = Date()
        let candidate = AlertCandidate(
            event: .fixture(startDate: now, endDate: now.addingTimeInterval(60)),
            offset: .fiveMinutesBefore
        )
        var store = AlertStateStore()

        XCTAssertEqual(store.takeLatest(from: [candidate], now: now), candidate)

        XCTAssertNil(store.takeLatest(from: [candidate], now: now.addingTimeInterval(30)))
        XCTAssertEqual(store.takeLatest(from: [candidate], now: now.addingTimeInterval(61)), candidate)
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

        XCTAssertNil(store.takeLatest(from: [first], now: now))
        XCTAssertEqual(store.takeLatest(from: [second], now: now), second)
    }

    func testNewestDueAlertSupersedesOlderAlertsWithoutReplayingThem() {
        let now = Date()
        let older = AlertCandidate(
            event: .fixture(id: "older", startDate: now.addingTimeInterval(-30)),
            offset: .atStart
        )
        let newer = AlertCandidate(event: .fixture(id: "newer", startDate: now), offset: .atStart)
        var store = AlertStateStore()

        XCTAssertEqual(store.takeLatest(from: [newer, older], now: now), newer)
        store.dismiss(newer)
        XCTAssertNil(store.takeLatest(from: [older, newer], now: now.addingTimeInterval(1)))
    }
}
