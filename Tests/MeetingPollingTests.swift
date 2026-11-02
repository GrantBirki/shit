import AppKit
@testable import Shit
import XCTest

final class MeetingPollingTests: XCTestCase {
    @MainActor
    func testMeetingPollRefreshesDuringMenuTracking() {
        _ = NSApplication.shared
        var refreshMode: RunLoop.Mode?
        let timer = AppController.scheduleMeetingPoll { refreshMode = RunLoop.main.currentMode }
        defer { timer.invalidate() }

        timer.fireDate = Date()
        let deadline = Date(timeIntervalSinceNow: 1)
        while refreshMode == nil, Date() < deadline {
            _ = RunLoop.main.run(mode: .eventTracking, before: deadline)
        }
        XCTAssertEqual(refreshMode, .eventTracking)
    }
}
