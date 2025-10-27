
import Foundation
import HealthKit

final class HealthKitManager {
    static let shared = HealthKitManager()
    let store = HKHealthStore()

    var sleepType: HKCategoryType? {
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    }

    func isAvailable() -> Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws -> Bool {
        guard isAvailable(), let sleepType = sleepType else { return false }
        let toShare: Set<HKSampleType> = []  // share is optional here
        let toRead: Set<HKObjectType> = [sleepType]
        return try await withCheckedThrowingContinuation { cont in
            store.requestAuthorization(toShare: toShare, read: toRead) { ok, err in
                if let err = err { cont.resume(throwing: err); return }
                cont.resume(returning: ok)
            }
        }
    }
}
