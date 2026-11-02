@testable import Shit
import XCTest

final class SettingsTabTests: XCTestCase {
    func testCyclingSettingsTabsInBothDirections() {
        XCTAssertEqual(SettingsTab.general.adjacent(forward: true), .alerts)
        XCTAssertEqual(SettingsTab.alerts.adjacent(forward: true), .calendars)
        XCTAssertEqual(SettingsTab.calendars.adjacent(forward: true), .general)
        XCTAssertEqual(SettingsTab.general.adjacent(forward: false), .calendars)
        XCTAssertEqual(SettingsTab.calendars.adjacent(forward: false), .alerts)
        XCTAssertEqual(SettingsTab.alerts.adjacent(forward: false), .general)
    }
}
