import Foundation

struct AlertStateStore {
    private var handledKeys: [AlertKey: Date] = [:]

    mutating func takeLatest(from dueAlerts: [AlertCandidate], now: Date) -> AlertCandidate? {
        handledKeys = handledKeys.filter { $0.value > now }
        let newAlerts = dueAlerts.filter { handledKeys[$0.key] == nil }
        for alert in newAlerts {
            handledKeys[alert.key] = alert.expirationDate
        }
        return newAlerts.max { $0.triggerDate < $1.triggerDate }
    }

    mutating func dismiss(_ candidate: AlertCandidate) {
        handledKeys[candidate.key] = candidate.expirationDate
    }
}
