import Foundation

struct MeetingFilterSettings: Equatable {
    var ignoreAllDayEvents: Bool
    var ignoreFreeEvents: Bool
    var ignoreDeclinedEvents: Bool
    var excludedCalendarIdentifiers: Set<String>
    var ignoredTitleKeywords: [String]

    init(
        ignoreAllDayEvents: Bool = true,
        ignoreFreeEvents: Bool = true,
        ignoreDeclinedEvents: Bool = true,
        excludedCalendarIdentifiers: Set<String> = [],
        ignoredTitleKeywords: [String] = []
    ) {
        self.ignoreAllDayEvents = ignoreAllDayEvents
        self.ignoreFreeEvents = ignoreFreeEvents
        self.ignoreDeclinedEvents = ignoreDeclinedEvents
        self.excludedCalendarIdentifiers = excludedCalendarIdentifiers
        self.ignoredTitleKeywords = ignoredTitleKeywords
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    init(settings: SettingsStore) {
        self.init(
            ignoreAllDayEvents: settings.ignoreAllDayEvents,
            ignoreFreeEvents: settings.ignoreFreeEvents,
            ignoreDeclinedEvents: settings.ignoreDeclinedEvents,
            excludedCalendarIdentifiers: settings.excludedCalendarIdentifiers,
            ignoredTitleKeywords: settings.ignoredTitleKeywords
        )
    }
}

struct AlertCandidate: Equatable {
    let event: MeetingEvent
    let offset: AlertOffset

    var key: AlertKey {
        AlertKey(eventID: event.id, occurrenceStart: event.startDate, offset: offset)
    }

    var triggerDate: Date {
        event.startDate.addingTimeInterval(offset.timeInterval)
    }

    var expirationDate: Date {
        event.endDate
    }
}

struct AlertKey: Hashable {
    let eventID: String
    let occurrenceStart: Date
    let offset: AlertOffset
}

enum AlertOffset: String, CaseIterable, Hashable {
    case fiveMinutesBefore
    case oneMinuteBefore
    case atStart

    var timeInterval: TimeInterval {
        switch self {
        case .fiveMinutesBefore:
            -300
        case .oneMinuteBefore:
            -60
        case .atStart:
            0
        }
    }

    var label: String {
        switch self {
        case .fiveMinutesBefore:
            "5 minutes before"
        case .oneMinuteBefore:
            "1 minute before"
        case .atStart:
            "At start"
        }
    }
}

struct MeetingDetector {
    var activeStartGrace: TimeInterval = 15 * 60
    var dueLookback: TimeInterval = 45

    func filteredEvents(
        events: [MeetingEvent],
        filter: MeetingFilterSettings,
        now: Date
    ) -> [MeetingEvent] {
        events
            .filter { event in shouldInclude(event, filter: filter, now: now) }
            .sorted { lhs, rhs in
                if lhs.startDate == rhs.startDate {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhs.startDate < rhs.startDate
            }
    }

    func dueAlerts(
        events: [MeetingEvent],
        filter: MeetingFilterSettings,
        timing: AlertTiming,
        now: Date
    ) -> [AlertCandidate] {
        dueAlerts(
            filteredEvents: filteredEvents(events: events, filter: filter, now: now),
            timing: timing,
            now: now
        )
    }

    func dueAlerts(
        filteredEvents events: [MeetingEvent],
        timing: AlertTiming,
        now: Date
    ) -> [AlertCandidate] {
        events
            .flatMap { event in
                timing.offsets.compactMap { offset -> AlertCandidate? in
                    let candidate = AlertCandidate(event: event, offset: offset)
                    return isDue(candidate, now: now) ? candidate : nil
                }
            }
            .sorted { $0.triggerDate < $1.triggerDate }
    }

    func currentMeeting(events: [MeetingEvent], filter: MeetingFilterSettings, now: Date) -> MeetingEvent? {
        filteredEvents(events: events, filter: filter, now: now)
            .first { $0.isActive(at: now) }
    }

    func nextMeeting(events: [MeetingEvent], filter: MeetingFilterSettings, now: Date) -> MeetingEvent? {
        filteredEvents(events: events, filter: filter, now: now)
            .first { $0.startDate > now }
    }

    private func isDue(_ candidate: AlertCandidate, now: Date) -> Bool {
        if candidate.offset == .atStart,
           candidate.event.isActive(at: now),
           now.timeIntervalSince(candidate.event.startDate) <= activeStartGrace
        {
            return true
        }

        let triggerDate = candidate.triggerDate
        guard now >= triggerDate else { return false }
        guard now <= candidate.event.endDate else { return false }
        return now.timeIntervalSince(triggerDate) <= dueLookback
    }

    private func shouldInclude(_ event: MeetingEvent, filter: MeetingFilterSettings, now _: Date) -> Bool {
        if filter.ignoreAllDayEvents, event.isAllDay {
            return false
        }
        if filter.ignoreFreeEvents, event.availability == .free {
            return false
        }
        if event.status == .canceled {
            return false
        }
        if filter.ignoreDeclinedEvents, event.participationStatus == .declined {
            return false
        }
        if filter.excludedCalendarIdentifiers.contains(event.calendarID) {
            return false
        }
        let normalizedTitle = event.title.localizedLowercase
        if filter.ignoredTitleKeywords.contains(where: { keyword in
            normalizedTitle.contains(keyword.localizedLowercase)
        }) {
            return false
        }
        return true
    }
}
