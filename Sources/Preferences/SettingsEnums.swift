import Foundation

struct AlertOffset: Hashable {
    static let supportedMinutes = 0 ... 120
    static let atStart = AlertOffset(uncheckedMinutesBefore: 0)
    static let oneMinuteBefore = AlertOffset(uncheckedMinutesBefore: 1)
    static let fiveMinutesBefore = AlertOffset(uncheckedMinutesBefore: 5)

    let minutesBefore: Int

    init?(minutesBefore: Int) {
        guard Self.supportedMinutes.contains(minutesBefore) else {
            return nil
        }
        self.minutesBefore = minutesBefore
    }

    private init(uncheckedMinutesBefore minutesBefore: Int) {
        self.minutesBefore = minutesBefore
    }

    var timeInterval: TimeInterval {
        -TimeInterval(minutesBefore * 60)
    }

    var label: String {
        switch minutesBefore {
        case 0:
            "At start"
        case 1:
            "1 minute before"
        default:
            "\(minutesBefore) minutes before"
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
