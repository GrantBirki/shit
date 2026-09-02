import Foundation

enum MeetingDateFormatter {
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    static var interval: DateIntervalFormatter {
        // DateIntervalFormatter can retain the old timezone after a system change.
        let formatter = DateIntervalFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }
}
