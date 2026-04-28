import Foundation
@testable import Shit

extension MeetingEvent {
    static func fixture(
        id: String = "event-1",
        title: String = "Team Meeting",
        calendarID: String = "calendar-1",
        startDate: Date,
        endDate: Date? = nil,
        isAllDay: Bool = false,
        availability: MeetingAvailability = .busy,
        status: MeetingStatus = .confirmed,
        participationStatus: MeetingParticipationStatus = .accepted
    ) -> MeetingEvent {
        MeetingEvent(
            id: id,
            calendarID: calendarID,
            calendarTitle: "Work",
            title: title,
            startDate: startDate,
            endDate: endDate ?? startDate.addingTimeInterval(1800),
            isAllDay: isAllDay,
            availability: availability,
            status: status,
            participationStatus: participationStatus
        )
    }
}
