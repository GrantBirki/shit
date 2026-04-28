import Foundation

enum AlertTiming: String, CaseIterable, Identifiable {
    case atStart
    case oneMinuteBefore
    case fiveMinutesBefore
    case oneMinuteAndStart

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .atStart:
            "At start"
        case .oneMinuteBefore:
            "1 minute before"
        case .fiveMinutesBefore:
            "5 minutes before"
        case .oneMinuteAndStart:
            "1 minute before + at start"
        }
    }

    var offsets: [AlertOffset] {
        switch self {
        case .atStart:
            [.atStart]
        case .oneMinuteBefore:
            [.oneMinuteBefore]
        case .fiveMinutesBefore:
            [.fiveMinutesBefore]
        case .oneMinuteAndStart:
            [.oneMinuteBefore, .atStart]
        }
    }
}

enum GlassProminence: String, CaseIterable, Identifiable {
    case subtle
    case balanced
    case prominent

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .subtle:
            "Subtle"
        case .balanced:
            "Balanced"
        case .prominent:
            "Prominent"
        }
    }
}
