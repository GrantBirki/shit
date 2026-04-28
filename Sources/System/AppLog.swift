import OSLog

enum AppLog {
    private static let subsystem = "io.birki.shit"

    static let pointsOfInterest = OSLog(subsystem: subsystem, category: .pointsOfInterest)
    static let app = Logger(subsystem: subsystem, category: "App")
    static let calendar = Logger(subsystem: subsystem, category: "Calendar")
    static let overlay = Logger(subsystem: subsystem, category: "Overlay")
    static let settings = Logger(subsystem: subsystem, category: "Settings")
    static let system = Logger(subsystem: subsystem, category: "System")
}

enum AppSignpost {
    static func begin(_ name: StaticString) -> OSSignpostID {
        let id = OSSignpostID(log: AppLog.pointsOfInterest)
        os_signpost(.begin, log: AppLog.pointsOfInterest, name: name, signpostID: id)
        return id
    }

    static func end(_ name: StaticString, id: OSSignpostID) {
        os_signpost(.end, log: AppLog.pointsOfInterest, name: name, signpostID: id)
    }

    static func event(_ name: StaticString) {
        os_signpost(.event, log: AppLog.pointsOfInterest, name: name)
    }
}
