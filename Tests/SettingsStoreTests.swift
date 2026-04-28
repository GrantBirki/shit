import Foundation
@testable import Shit
import XCTest

final class SettingsStoreTests: XCTestCase {
    func testDefaultSettingsMatchPlan() throws {
        let suite = "SettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let settings = SettingsStore(defaults: defaults)

        XCTAssertEqual(settings.alertTiming, .fiveMinutesBefore)
        XCTAssertTrue(settings.ignoreAllDayEvents)
        XCTAssertTrue(settings.ignoreFreeEvents)
        XCTAssertTrue(settings.ignoreDeclinedEvents)
        XCTAssertTrue(settings.excludedCalendarIdentifiers.isEmpty)
        XCTAssertTrue(settings.ignoredTitleKeywords.isEmpty)
        XCTAssertFalse(settings.autoLaunchEnabled)
    }

    func testPersistsSettings() throws {
        let suite = "SettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        var settings: SettingsStore? = SettingsStore(defaults: defaults)
        settings?.alertTiming = .fiveMinutesBefore
        settings?.ignoreAllDayEvents = false
        settings?.ignoreFreeEvents = false
        settings?.ignoreDeclinedEvents = false
        settings?.excludedCalendarIdentifiers = ["calendar-a"]
        settings?.ignoredTitleKeywordsText = "hold\nfocus"
        settings?.autoLaunchEnabled = true
        settings = nil

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.alertTiming, .fiveMinutesBefore)
        XCTAssertFalse(reloaded.ignoreAllDayEvents)
        XCTAssertFalse(reloaded.ignoreFreeEvents)
        XCTAssertFalse(reloaded.ignoreDeclinedEvents)
        XCTAssertEqual(reloaded.excludedCalendarIdentifiers, Set(["calendar-a"]))
        XCTAssertEqual(reloaded.ignoredTitleKeywords, ["hold", "focus"])
        XCTAssertTrue(reloaded.autoLaunchEnabled)
    }

    func testInvalidStoredAlertTimingFallsBackToDefault() throws {
        let suite = "SettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defaults.set("not-a-real-alert-mode", forKey: SettingsStoreKeys.alertTiming)

        let settings = SettingsStore(defaults: defaults)

        XCTAssertEqual(settings.alertTiming, .fiveMinutesBefore)
    }

    func testIgnoredKeywordsTrimsWhitespaceAndDropsEmptyLines() throws {
        let suite = "SettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let settings = SettingsStore(defaults: defaults)
        settings.ignoredTitleKeywordsText = "\n hold \n\n focus\n  "

        XCTAssertEqual(settings.ignoredTitleKeywords, ["hold", "focus"])
    }
}
