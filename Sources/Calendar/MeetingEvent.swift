import Foundation

struct MeetingEvent: Equatable, Identifiable {
    let id: String
    let calendarID: String
    let calendarTitle: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let availability: MeetingAvailability
    let status: MeetingStatus
    let participationStatus: MeetingParticipationStatus

    init(
        id: String,
        calendarID: String,
        calendarTitle: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        availability: MeetingAvailability = .busy,
        status: MeetingStatus = .confirmed,
        participationStatus: MeetingParticipationStatus = .accepted
    ) {
        self.id = id
        self.calendarID = calendarID
        self.calendarTitle = calendarTitle
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.availability = availability
        self.status = status
        self.participationStatus = participationStatus
    }

    func isActive(at date: Date) -> Bool {
        date >= startDate && date < endDate
    }

    var timeRangeLabel: String {
        MeetingDateFormatter.interval.string(from: startDate, to: endDate)
    }
}

enum MeetingAvailability: String, Equatable {
    case busy
    case free
    case tentative
    case unavailable
    case unknown
}

enum MeetingStatus: String, Equatable {
    case confirmed
    case tentative
    case canceled
    case unknown
}

enum MeetingParticipationStatus: String, Equatable {
    case accepted
    case declined
    case tentative
    case pending
    case unknown
}
