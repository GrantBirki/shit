import Foundation

private typealias Keys = SettingsStoreKeys

final class SettingsStore: ObservableObject {
    @Published var alertTiming: AlertTiming {
        didSet { defaults.set(alertTiming.rawValue, forKey: Keys.alertTiming) }
    }

    @Published var ignoreAllDayEvents: Bool {
        didSet { defaults.set(ignoreAllDayEvents, forKey: Keys.ignoreAllDayEvents) }
    }

    @Published var ignoreFreeEvents: Bool {
        didSet { defaults.set(ignoreFreeEvents, forKey: Keys.ignoreFreeEvents) }
    }

    @Published var ignoreDeclinedEvents: Bool {
        didSet { defaults.set(ignoreDeclinedEvents, forKey: Keys.ignoreDeclinedEvents) }
    }

    @Published var excludedCalendarIdentifiers: Set<String> {
        didSet { defaults.set(Array(excludedCalendarIdentifiers).sorted(), forKey: Keys.excludedCalendarIdentifiers) }
    }

    @Published var ignoredTitleKeywordsText: String {
        didSet { defaults.set(ignoredTitleKeywordsText, forKey: Keys.ignoredTitleKeywordsText) }
    }

    @Published var autoLaunchEnabled: Bool {
        didSet { defaults.set(autoLaunchEnabled, forKey: Keys.autoLaunchEnabled) }
    }

    var ignoredTitleKeywords: [String] {
        ignoredTitleKeywordsText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        alertTiming = Self.loadEnum(
            AlertTiming.self,
            from: defaults,
            key: Keys.alertTiming,
            defaultValue: .fiveMinutesBefore
        )
        ignoreAllDayEvents = defaults.object(forKey: Keys.ignoreAllDayEvents) as? Bool ?? true
        ignoreFreeEvents = defaults.object(forKey: Keys.ignoreFreeEvents) as? Bool ?? true
        ignoreDeclinedEvents = defaults.object(forKey: Keys.ignoreDeclinedEvents) as? Bool ?? true
        excludedCalendarIdentifiers = Set(defaults.stringArray(forKey: Keys.excludedCalendarIdentifiers) ?? [])
        ignoredTitleKeywordsText = defaults.string(forKey: Keys.ignoredTitleKeywordsText) ?? ""
        autoLaunchEnabled = defaults.object(forKey: Keys.autoLaunchEnabled) as? Bool ?? false
    }

    private static func loadEnum<T: RawRepresentable>(
        _ type: T.Type,
        from defaults: UserDefaults,
        key: String,
        defaultValue: T
    ) -> T where T.RawValue == String {
        guard let rawValue = defaults.string(forKey: key),
              let value = type.init(rawValue: rawValue)
        else {
            return defaultValue
        }
        return value
    }
}
