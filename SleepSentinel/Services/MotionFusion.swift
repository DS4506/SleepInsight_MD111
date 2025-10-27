
import Foundation
import CoreMotion

final class MotionFusion {
    private let manager = CMMotionActivityManager()
    private let queue = OperationQueue()

    func requestAuthIfNeeded() {
        if CMMotionActivityManager.authorizationStatus() == .notDetermined,
           CMMotionActivityManager.isActivityAvailable() {
            manager.queryActivityStarting(from: Date().addingTimeInterval(-1800),
                                          to: Date(),
                                          to: queue) { _, _ in }
        }
    }

    // Low-power heuristic: look for stationary near targetBed and active near targetWake
    func inferOnsetAndWake(targetBed: Date, targetWake: Date, completion: @escaping (Date?, Date?) -> Void) {
        guard CMMotionActivityManager.isActivityAvailable() else { completion(nil, nil); return }
        let start = targetBed.addingTimeInterval(-60 * 30)
        let end = targetWake.addingTimeInterval(60 * 90)

        manager.queryActivityStarting(from: start, to: end, to: queue) { activities, _ in
            guard let activities = activities, !activities.isEmpty else { completion(nil, nil); return }
            let onset = activities.filter { $0.stationary }
                .map { $0.startDate }
                .sorted()
                .first { abs($0.timeIntervalSince(targetBed)) <= 60 * 90 }
            let wake = activities.filter { $0.walking || $0.running || $0.automotive || $0.cycling }
                .map { $0.startDate }
                .sorted()
                .first { abs($0.timeIntervalSince(targetWake)) <= 60 * 90 }
            completion(onset, wake)
        }
    }
}
