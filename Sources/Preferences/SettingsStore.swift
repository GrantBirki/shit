import Foundation

private typealias Keys = SettingsStoreKeys

final class SettingsStore: ObservableObject {
    private struct StoredAlertSchedule {
        let first: Int
        let second: Int?
        let wasMigrated: Bool
    }

    @Published private(set) var firstAlertMinutes: Int
    @Published private(set) var secondAlertMinutes: Int?

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

    @Published var menuBarIconVisible: Bool {
        didSet { defaults.set(menuBarIconVisible, forKey: Keys.menuBarIconVisible) }
    }

    var ignoredTitleKeywords: [String] {
        ignoredTitleKeywordsText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var alertOffsets: [AlertOffset] {
        var minutes = [firstAlertMinutes]
        if let secondAlertMinutes {
            minutes.append(secondAlertMinutes)
        }
        return minutes.compactMap(AlertOffset.init(minutesBefore:))
    }

    var canEnableSecondAlert: Bool {
        firstAlertMinutes > 0
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let alertSchedule = Self.loadAlertSchedule(from: defaults)
        firstAlertMinutes = alertSchedule.first
        secondAlertMinutes = alertSchedule.second
        ignoreAllDayEvents = defaults.object(forKey: Keys.ignoreAllDayEvents) as? Bool ?? true
        ignoreFreeEvents = defaults.object(forKey: Keys.ignoreFreeEvents) as? Bool ?? true
        ignoreDeclinedEvents = defaults.object(forKey: Keys.ignoreDeclinedEvents) as? Bool ?? true
        excludedCalendarIdentifiers = Set(defaults.stringArray(forKey: Keys.excludedCalendarIdentifiers) ?? [])
        ignoredTitleKeywordsText = defaults.string(forKey: Keys.ignoredTitleKeywordsText) ?? ""
        autoLaunchEnabled = defaults.object(forKey: Keys.autoLaunchEnabled) as? Bool ?? false
        menuBarIconVisible = defaults.object(forKey: Keys.menuBarIconVisible) as? Bool ?? true

        if alertSchedule.wasMigrated {
            defaults.set(alertSchedule.first, forKey: Keys.firstAlertMinutes)
            if let second = alertSchedule.second {
                defaults.set(second, forKey: Keys.secondAlertMinutes)
            } else {
                defaults.removeObject(forKey: Keys.secondAlertMinutes)
            }
        }
    }

    func setFirstAlertMinutes(_ minutes: Int) {
        guard AlertOffset.supportedMinutes.contains(minutes) else { return }

        firstAlertMinutes = minutes
        defaults.set(minutes, forKey: Keys.firstAlertMinutes)
        if let secondAlertMinutes, secondAlertMinutes >= minutes {
            setSecondAlertMinutes(nil)
        }
    }

    func setSecondAlertEnabled(_ enabled: Bool) {
        guard enabled else {
            setSecondAlertMinutes(nil)
            return
        }
        guard let defaultMinutes = defaultSecondAlertMinutes else { return }
        setSecondAlertMinutes(defaultMinutes)
    }

    func setSecondAlertMinutes(_ minutes: Int?) {
        guard let minutes else {
            secondAlertMinutes = nil
            defaults.removeObject(forKey: Keys.secondAlertMinutes)
            return
        }
        guard AlertOffset.supportedMinutes.contains(minutes), minutes < firstAlertMinutes else {
            setSecondAlertMinutes(nil)
            return
        }

        secondAlertMinutes = minutes
        defaults.set(minutes, forKey: Keys.secondAlertMinutes)
    }

    private var defaultSecondAlertMinutes: Int? {
        if firstAlertMinutes > 5 {
            return 5
        }
        if firstAlertMinutes > 1 {
            return 1
        }
        if firstAlertMinutes > 0 {
            return 0
        }
        return nil
    }

    private static func loadAlertSchedule(
        from defaults: UserDefaults
    ) -> StoredAlertSchedule {
        if defaults.object(forKey: Keys.firstAlertMinutes) != nil {
            guard let first = defaults.object(forKey: Keys.firstAlertMinutes) as? Int,
                  AlertOffset.supportedMinutes.contains(first)
            else {
                return StoredAlertSchedule(first: 5, second: nil, wasMigrated: false)
            }

            guard defaults.object(forKey: Keys.secondAlertMinutes) != nil else {
                return StoredAlertSchedule(first: first, second: nil, wasMigrated: false)
            }
            guard let second = defaults.object(forKey: Keys.secondAlertMinutes) as? Int,
                  AlertOffset.supportedMinutes.contains(second),
                  second < first
            else {
                return StoredAlertSchedule(first: 5, second: nil, wasMigrated: false)
            }
            return StoredAlertSchedule(first: first, second: second, wasMigrated: false)
        }

        switch defaults.string(forKey: Keys.alertTiming) {
        case "atStart":
            return StoredAlertSchedule(first: 0, second: nil, wasMigrated: true)
        case "oneMinuteBefore":
            return StoredAlertSchedule(first: 1, second: nil, wasMigrated: true)
        case "oneMinuteAndStart":
            return StoredAlertSchedule(first: 1, second: 0, wasMigrated: true)
        case "fiveMinutesBefore":
            return StoredAlertSchedule(first: 5, second: nil, wasMigrated: true)
        default:
            return StoredAlertSchedule(first: 5, second: nil, wasMigrated: false)
        }
    }
}
