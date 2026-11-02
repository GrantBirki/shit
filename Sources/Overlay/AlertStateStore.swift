import Foundation

struct AlertStateStore {
    private var handledKeys: [AlertKey: Date] = [:]

    private var pausedKeys: Set<AlertKey> = []
    private(set) var pendingKeys: Set<AlertKey> = []

    mutating func takeNext(from dueAlerts: [AlertCandidate], now: Date, canPresent: Bool = true) -> AlertCandidate? {
        handledKeys = handledKeys.filter { $0.value > now }
        let newAlerts = dueAlerts.filter { handledKeys[$0.key] == nil }
        pendingKeys = Set(newAlerts.map(\.key))
        pausedKeys.formIntersection(pendingKeys)
        guard canPresent, let next = newAlerts.first(where: { !pausedKeys.contains($0.key) }) else { return nil }
        pendingKeys.remove(next.key)
        handledKeys[next.key] = next.expirationDate
        return next
    }

    mutating func pausePending() {
        pausedKeys = pendingKeys
    }

    mutating func resumePending() {
        pausedKeys.removeAll()
    }

    mutating func clearPending() {
        pendingKeys.removeAll()
        pausedKeys.removeAll()
    }

    mutating func dismiss(_ candidate: AlertCandidate) {
        handledKeys[candidate.key] = candidate.expirationDate
    }
}
