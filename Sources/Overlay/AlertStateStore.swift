import Foundation

struct AlertStateStore {
    private var dismissedKeys: [AlertKey: Date] = [:]
    private var presentedKeys: [AlertKey: Date] = [:]

    mutating func shouldPresent(_ candidate: AlertCandidate, now: Date) -> Bool {
        prune(expiredBefore: now)
        if dismissedKeys[candidate.key] != nil {
            return false
        }
        if presentedKeys[candidate.key] != nil {
            return false
        }
        return true
    }

    mutating func markPresented(_ candidate: AlertCandidate) {
        presentedKeys[candidate.key] = candidate.expirationDate
    }

    mutating func dismiss(_ candidate: AlertCandidate) {
        dismissedKeys[candidate.key] = candidate.expirationDate
    }

    private mutating func prune(expiredBefore date: Date) {
        dismissedKeys = dismissedKeys.filter { $0.value > date }
        presentedKeys = presentedKeys.filter { $0.value > date }
    }
}
