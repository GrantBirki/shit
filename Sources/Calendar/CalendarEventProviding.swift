import Foundation

@MainActor
protocol CalendarEventProviding: AnyObject {
    var authorizationState: CalendarAuthorizationState { get }

    func requestAccess() async -> CalendarAuthorizationState
    func calendars() -> [CalendarSource]
    func events(start: Date, end: Date) -> [MeetingEvent]
}

struct CalendarSource: Equatable, Identifiable {
    let id: String
    let title: String
    let colorHex: String?
}
