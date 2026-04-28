import AppKit
import EventKit
import Foundation

final class EventKitCalendarEventProvider: CalendarEventProviding {
    private let eventStore: EKEventStore

    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    var authorizationState: CalendarAuthorizationState {
        CalendarAuthorizationState(status: EKEventStore.authorizationStatus(for: .event))
    }

    func requestAccess() async -> CalendarAuthorizationState {
        do {
            _ = try await eventStore.requestFullAccessToEvents()
        } catch {
            AppLog.calendar.error("Calendar access request failed: \(String(describing: error), privacy: .public)")
        }
        return authorizationState
    }

    func calendars() -> [CalendarSource] {
        guard authorizationState.canReadEvents else { return [] }
        return eventStore.calendars(for: .event)
            .map { calendar in
                CalendarSource(
                    id: calendar.calendarIdentifier,
                    title: calendar.title,
                    colorHex: calendar.cgColor.flatMap(Self.hexColor)
                )
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func events(start: Date, end: Date) -> [MeetingEvent] {
        guard authorizationState.canReadEvents else { return [] }
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate)
            .map(MeetingEvent.init(event:))
            .sorted { $0.startDate < $1.startDate }
    }

    nonisolated static func hexColor(_ cgColor: CGColor) -> String? {
        guard let color = NSColor(cgColor: cgColor)?.usingColorSpace(.deviceRGB) else { return nil }
        let red = Int(round(color.redComponent * 255))
        let green = Int(round(color.greenComponent * 255))
        let blue = Int(round(color.blueComponent * 255))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

private extension MeetingEvent {
    init(event: EKEvent) {
        let participationStatus = event.attendees?
            .first(where: { $0.isCurrentUser })?
            .participantStatus

        self.init(
            id: event.eventIdentifier ?? event.calendarItemIdentifier,
            calendarID: event.calendar.calendarIdentifier,
            calendarTitle: event.calendar.title,
            title: event.title?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? "Untitled Meeting",
            startDate: event.startDate,
            endDate: event.endDate,
            isAllDay: event.isAllDay,
            availability: MeetingAvailability(eventAvailability: event.availability),
            status: MeetingStatus(eventStatus: event.status),
            participationStatus: participationStatus
                .map { MeetingParticipationStatus(eventParticipantStatus: $0) } ?? .unknown
        )
    }
}

extension MeetingAvailability {
    init(eventAvailability availability: EKEventAvailability) {
        switch availability {
        case .busy:
            self = .busy
        case .free:
            self = .free
        case .tentative:
            self = .tentative
        case .unavailable:
            self = .unavailable
        case .notSupported:
            self = .unknown
        @unknown default:
            self = .unknown
        }
    }
}

extension MeetingStatus {
    init(eventStatus status: EKEventStatus) {
        switch status {
        case .confirmed:
            self = .confirmed
        case .tentative:
            self = .tentative
        case .canceled:
            self = .canceled
        case .none:
            self = .unknown
        @unknown default:
            self = .unknown
        }
    }
}

extension MeetingParticipationStatus {
    init(eventParticipantStatus status: EKParticipantStatus) {
        switch status {
        case .accepted:
            self = .accepted
        case .declined:
            self = .declined
        case .tentative:
            self = .tentative
        case .pending:
            self = .pending
        case .delegated,
             .completed,
             .inProcess,
             .unknown:
            self = .unknown
        @unknown default:
            self = .unknown
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
