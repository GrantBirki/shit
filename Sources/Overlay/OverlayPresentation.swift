import Foundation

enum OverlayPresentation {
    static func statusText(for event: MeetingEvent, now: Date) -> String {
        if event.isActive(at: now) {
            return "Meeting is live"
        }
        let seconds = max(0, Int(event.startDate.timeIntervalSince(now)))
        if seconds < 60 {
            return "Starts in less than a minute"
        }
        return "Starts in \(seconds / 60) minutes"
    }
}
