import Foundation
@testable import Shit
import XCTest

final class SettingsStoreTests: XCTestCase {
    private struct LegacyAlertCase {
        let rawValue: String
        let first: Int
        let second: Int?
    }

    func testDefaultSettingsMatchPlan() throws {
        let settings = try SettingsStore(defaults: makeDefaults())

        XCTAssertEqual(settings.firstAlertMinutes, 5)
        XCTAssertNil(settings.secondAlertMinutes)
        XCTAssertEqual(settings.alertOffsets, [.fiveMinutesBefore])
        XCTAssertTrue(settings.ignoreAllDayEvents)
        XCTAssertTrue(settings.ignoreFreeEvents)
        XCTAssertTrue(settings.ignoreDeclinedEvents)
        XCTAssertTrue(settings.excludedCalendarIdentifiers.isEmpty)
        XCTAssertTrue(settings.ignoredTitleKeywords.isEmpty)
        XCTAssertFalse(settings.autoLaunchEnabled)
        XCTAssertTrue(settings.menuBarIconVisible)
    }

    func testPersistsSettings() throws {
        let defaults = try makeDefaults()
        var settings: SettingsStore? = SettingsStore(defaults: defaults)
        settings?.setFirstAlertMinutes(30)
        settings?.setSecondAlertMinutes(5)
        settings?.ignoreAllDayEvents = false
        settings?.ignoreFreeEvents = false
        settings?.ignoreDeclinedEvents = false
        settings?.excludedCalendarIdentifiers = ["calendar-a"]
        settings?.ignoredTitleKeywordsText = "hold\nfocus"
        settings?.autoLaunchEnabled = true
        settings?.menuBarIconVisible = false
        settings = nil

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.firstAlertMinutes, 30)
        XCTAssertEqual(reloaded.secondAlertMinutes, 5)
        let thirtyMinutes = try XCTUnwrap(AlertOffset(minutesBefore: 30))
        XCTAssertEqual(reloaded.alertOffsets, [thirtyMinutes, .fiveMinutesBefore])
        XCTAssertFalse(reloaded.ignoreAllDayEvents)
        XCTAssertFalse(reloaded.ignoreFreeEvents)
        XCTAssertFalse(reloaded.ignoreDeclinedEvents)
        XCTAssertEqual(reloaded.excludedCalendarIdentifiers, Set(["calendar-a"]))
        XCTAssertEqual(reloaded.ignoredTitleKeywords, ["hold", "focus"])
        XCTAssertTrue(reloaded.autoLaunchEnabled)
        XCTAssertFalse(reloaded.menuBarIconVisible)
    }

    func testMigratesLegacyAlertTimingValues() throws {
        let cases = [
            LegacyAlertCase(rawValue: "fiveMinutesBefore", first: 5, second: nil),
            LegacyAlertCase(rawValue: "oneMinuteBefore", first: 1, second: nil),
            LegacyAlertCase(rawValue: "atStart", first: 0, second: nil),
            LegacyAlertCase(rawValue: "oneMinuteAndStart", first: 1, second: 0),
        ]

        for testCase in cases {
            let defaults = try makeDefaults()
            defaults.set(testCase.rawValue, forKey: SettingsStoreKeys.alertTiming)

            let settings = SettingsStore(defaults: defaults)

            XCTAssertEqual(settings.firstAlertMinutes, testCase.first, testCase.rawValue)
            XCTAssertEqual(settings.secondAlertMinutes, testCase.second, testCase.rawValue)
            XCTAssertEqual(defaults.integer(forKey: SettingsStoreKeys.firstAlertMinutes), testCase.first)
            XCTAssertEqual(
                defaults.object(forKey: SettingsStoreKeys.secondAlertMinutes) as? Int,
                testCase.second
            )
        }
    }

    func testInvalidLegacyAlertTimingFallsBackToDefault() throws {
        let defaults = try makeDefaults()
        defaults.set("not-a-real-alert-mode", forKey: SettingsStoreKeys.alertTiming)

        let settings = SettingsStore(defaults: defaults)

        XCTAssertEqual(settings.firstAlertMinutes, 5)
        XCTAssertNil(settings.secondAlertMinutes)
    }

    func testInvalidStoredScheduleFallsBackToDefault() throws {
        let invalidSchedules: [(first: Any, second: Any?)] = [
            (-1, nil),
            (121, nil),
            ("invalid", nil),
            (5, 5),
            (5, 30),
            (30, 121),
            (30, "invalid"),
        ]

        for schedule in invalidSchedules {
            let defaults = try makeDefaults()
            defaults.set(schedule.first, forKey: SettingsStoreKeys.firstAlertMinutes)
            if let second = schedule.second {
                defaults.set(second, forKey: SettingsStoreKeys.secondAlertMinutes)
            }

            let settings = SettingsStore(defaults: defaults)

            XCTAssertEqual(settings.firstAlertMinutes, 5)
            XCTAssertNil(settings.secondAlertMinutes)
        }
    }

    func testEnablingSecondAlertChoosesClosestConventionalDefault() throws {
        let settings = try SettingsStore(defaults: makeDefaults())

        settings.setFirstAlertMinutes(30)
        settings.setSecondAlertEnabled(true)
        XCTAssertEqual(settings.secondAlertMinutes, 5)

        settings.setSecondAlertEnabled(false)
        settings.setFirstAlertMinutes(5)
        settings.setSecondAlertEnabled(true)
        XCTAssertEqual(settings.secondAlertMinutes, 1)

        settings.setSecondAlertEnabled(false)
        settings.setFirstAlertMinutes(1)
        settings.setSecondAlertEnabled(true)
        XCTAssertEqual(settings.secondAlertMinutes, 0)

        settings.setSecondAlertEnabled(false)
        settings.setFirstAlertMinutes(0)
        settings.setSecondAlertEnabled(true)
        XCTAssertNil(settings.secondAlertMinutes)
    }

    func testChangingFirstAlertDisablesInvalidSecondAlert() throws {
        let settings = try SettingsStore(defaults: makeDefaults())
        settings.setFirstAlertMinutes(30)
        settings.setSecondAlertMinutes(5)

        settings.setFirstAlertMinutes(5)

        XCTAssertEqual(settings.firstAlertMinutes, 5)
        XCTAssertNil(settings.secondAlertMinutes)
    }

    func testRejectsInvalidRuntimeValues() throws {
        let settings = try SettingsStore(defaults: makeDefaults())
        settings.setFirstAlertMinutes(30)
        settings.setSecondAlertMinutes(5)

        settings.setFirstAlertMinutes(121)
        XCTAssertEqual(settings.firstAlertMinutes, 30)
        XCTAssertEqual(settings.secondAlertMinutes, 5)

        settings.setSecondAlertMinutes(30)
        XCTAssertNil(settings.secondAlertMinutes)
    }

    func testIgnoredKeywordsTrimsWhitespaceAndDropsEmptyLines() throws {
        let settings = try SettingsStore(defaults: makeDefaults())
        settings.ignoredTitleKeywordsText = "\n hold \n\n focus\n  "

        XCTAssertEqual(settings.ignoredTitleKeywords, ["hold", "focus"])
    }

    private func makeDefaults() throws -> UserDefaults {
        let suite = "SettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
