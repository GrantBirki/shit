import EventKit

enum CalendarAuthorizationState: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case writeOnly
    case unknown

    init(status: EKAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .fullAccess:
            self = .authorized
        case .writeOnly:
            self = .writeOnly
        @unknown default:
            self = .unknown
        }
    }

    var canReadEvents: Bool {
        self == .authorized
    }

    var menuTitle: String {
        switch self {
        case .notDetermined:
            "Calendar access not requested"
        case .authorized:
            "Calendar access granted"
        case .denied:
            "Calendar access denied"
        case .restricted:
            "Calendar access restricted"
        case .writeOnly:
            "Calendar access is write-only"
        case .unknown:
            "Calendar access unknown"
        }
    }
}
