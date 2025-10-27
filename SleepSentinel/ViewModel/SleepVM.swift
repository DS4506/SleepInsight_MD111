
import Foundation
import SwiftUI
import Combine
import HealthKit
import UserNotifications

@MainActor
final class SleepVM: ObservableObject {
    @Published var nights: [SleepNight] = []
    @Published var settings = SleepSettings(
        targetBedtime: .init(hour: 23, minute: 0),
        targetWake: .init(hour: 7, minute: 0)
    )
    @Published var hkAuthorized: Bool = false
    @Published var lastUpdate: Date? = nil
    @Published var weeklyNow: WeeklySummary? = nil
    @Published var weeklyPrev: WeeklySummary? = nil
    @Published var recommendations: [Recommendation] = []

    private let hk = HealthKitManager.shared
    private let store = SleepStore.shared
    private let motion = MotionFusion()

    private var anchor: HKQueryAnchor? = nil

    // MARK: Bootstrap
    func bootstrap() {
        if let payload = store.load() {
            nights = payload.nights
            settings = payload.settings
            if let data = payload.lastAnchorData {
                anchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
            }
        }
        recomputeAll()
        observeDayChange()
    }

    // MARK: Permissions
    func requestPermissions() async {
        do {
            hkAuthorized = try await hk.requestAuthorization()
            if hkAuthorized {
                startObservers()
                await fetchDeltas()
            }
        } catch {
            hkAuthorized = false
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: Observer + Anchored
    private func startObservers() {
        guard let sleepType = hk.sleepType else { return }
        let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, completion, _ in
            Task { await self?.fetchDeltas(); completion() }
        }
        hk.store.execute(query)
        hk.store.enableBackgroundDelivery(for: sleepType, frequency: .immediate) { _, _ in }
    }

    private func fetchDeltasPredicate() -> NSPredicate {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -14, to: end)!
        return HKQuery.predicateForSamples(withStart: start, end: end, options: [])
    }

    func fetchDeltas() async {
        guard let sleepType = hk.sleepType else { return }
        let predicate = fetchDeltasPredicate()
        var newAnchor: HKQueryAnchor? = anchor
        var collected: [HKSample] = []

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let anchored = HKAnchoredObjectQuery(
                type: sleepType,
                predicate: predicate,
                anchor: newAnchor,
                limit: HKObjectQueryNoLimit
            ) { [weak self] _, samplesOrNil, _, newAnchorOrNil, _ in
                if let s = samplesOrNil { collected.append(contentsOf: s) }
                newAnchor = newAnchorOrNil
                self?.apply(samples: collected)
                self?.anchor = newAnchor
                self?.persist()
                cont.resume()
            }
            hk.store.execute(anchored)
        }
    }

    private func apply(samples: [HKSample]) {
        guard let catSamples = samples as? [HKCategorySample] else { return }
        var nightsByKey: [String: [HKCategorySample]] = [:]
        for s in catSamples {
            let key = nightKey(for: s.startDate)
            nightsByKey[key, default: []].append(s)
        }
        for (key, arr) in nightsByKey {
            let sorted = arr.sorted { $0.startDate < $1.startDate }
            let nightDate = dateFromNightKey(key)
            let inBedTotal = totalDuration(of: sorted, category: .inBed)
            let asleepTotal = totalDuration(of: sorted, category: .asleepUnspecified)
                + totalDuration(of: sorted, category: .asleepCore)
                + totalDuration(of: sorted, category: .asleepREM)
                + totalDuration(of: sorted, category: .asleepDeep)

            let bedtime = sorted.first?.startDate
            let wake = sorted.last?.endDate
            let midpoint = midpointDate(start: bedtime, end: wake)
            let eff = computeEfficiency(asleep: asleepTotal, inBed: inBedTotal)

            let newNight = SleepNight(
                date: nightDate,
                inBed: inBedTotal > 0 ? inBedTotal : nil,
                asleep: asleepTotal > 0 ? asleepTotal : nil,
                bedtime: bedtime,
                wake: wake,
                midpoint: midpoint,
                efficiency: eff,
                inferred: false
            )
            upsert(night: newNight)
        }
        sortNights()
        recomputeAll()
    }

    // MARK: Motion fusion
    func runMotionFusion() {
        motion.requestAuthIfNeeded()
        guard let targetBed = timeOn(date: Date(), comps: settings.targetBedtime),
              let targetWake = timeOn(date: Date().addingTimeInterval(60*60*8), comps: settings.targetWake) else { return }

        motion.inferOnsetAndWake(targetBed: targetBed, targetWake: targetWake) { [weak self] onset, wake in
            Task { @MainActor in
                guard let self = self else { return }
                let anchorDate = self.nightAnchor(for: targetBed)
                let interval = max(60.0, wake?.timeIntervalSince(onset ?? targetBed) ?? 0)
                let midpoint = self.midpointDate(start: onset ?? targetBed, end: wake ?? targetWake)

                if let idx = self.nights.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: anchorDate) }) {
                    var n = self.nights[idx]
                    n.bedtime = n.bedtime ?? onset
                    n.wake = n.wake ?? wake
                    n.asleep = n.asleep ?? interval
                    n.midpoint = n.midpoint ?? midpoint
                    n.efficiency = self.computeEfficiency(asleep: n.asleep, inBed: n.inBed)
                    n.inferred = true
                    self.nights[idx] = n
                } else {
                    let newNight = SleepNight(
                        date: anchorDate,
                        inBed: nil,
                        asleep: interval,
                        bedtime: onset,
                        wake: wake,
                        midpoint: midpoint,
                        efficiency: nil,
                        inferred: true
                    )
                    self.nights.append(newNight)
                }
                self.sortNights()
                self.persist()
                self.recomputeAll()
            }
        }
    }

    // MARK: Metrics
    private func computeEfficiency(asleep: TimeInterval?, inBed: TimeInterval?) -> Double? {
        guard let a = asleep, let b = inBed, b > 0 else { return nil }
        return a / b
    }

    private func midpointDate(start: Date?, end: Date?) -> Date? {
        guard let s = start, let e = end, e >= s else { return nil }
        return s.addingTimeInterval(e.timeIntervalSince(s) / 2)
    }

    func makeWeeklySummary(windowDays: Int = 7, startIndex: Int = 0) -> WeeklySummary? {
        guard !nights.isEmpty else { return nil }
        let slice = Array(nights.dropFirst(startIndex).prefix(windowDays))
        guard !slice.isEmpty else { return nil }
        let avgDur = averageDurationMinutes(slice)
        let avgMid = averageMidpoint(slice)
        let sj = socialJetlagHours(slice)
        let reg = regularityPercent(slice, settings: settings)
        let std = midpointStdDevMinutes(slice)
        let best = slice.max(by: { ($0.asleep ?? 0) < ($1.asleep ?? 0) })
        let worst = slice.min(by: { ($0.asleep ?? 0) < ($1.asleep ?? 0) })
        return WeeklySummary(
            start: slice.last!.date,
            end: slice.first!.date,
            avgDurationMin: avgDur,
            avgMidpoint: avgMid,
            socialJetlagHrs: sj,
            regularityPct: reg,
            midpointStdDevMin: std,
            bestNight: best,
            worstNight: worst
        )
    }

    func rebuildSummaries() {
        weeklyNow = makeWeeklySummary(windowDays: 7, startIndex: 0)
        weeklyPrev = makeWeeklySummary(windowDays: 7, startIndex: 7)
        if let now = weeklyNow { recommendations = makeRecommendations(current: now, previous: weeklyPrev) }
        else { recommendations = [] }
    }

    private func averageDurationMinutes(_ arr: [SleepNight]) -> Double {
        let mins = arr.compactMap { $0.asleep.map { $0 / 60.0 } }
        guard !mins.isEmpty else { return 0 }
        return mins.reduce(0, +) / Double(mins.count)
    }

    private func averageMidpoint(_ arr: [SleepNight]) -> Date? {
        let mids = arr.compactMap { $0.midpoint?.timeIntervalSinceReferenceDate }
        guard !mids.isEmpty else { return nil }
        let m = mids.reduce(0, +) / Double(mids.count)
        return Date(timeIntervalSinceReferenceDate: m)
    }

    private func socialJetlagHours(_ arr: [SleepNight]) -> Double {
        let cal = Calendar.current
        let wk = arr.compactMap { !cal.isDateInWeekend($0.date) ? $0.midpoint : nil }
        let wkd = arr.compactMap { cal.isDateInWeekend($0.date) ? $0.midpoint : nil }
        guard !wk.isEmpty, !wkd.isEmpty else { return 0 }
        let aw = wk.map { $0.timeIntervalSinceReferenceDate }.reduce(0, +) / Double(wk.count)
        let ae = wkd.map { $0.timeIntervalSinceReferenceDate }.reduce(0, +) / Double(wkd.count)
        return abs(aw - ae) / 3600.0
    }

    private func targetMidpoint(on ref: Date = Date()) -> Date? {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: ref)
        guard let bed = cal.date(from: DateComponents(year: comps.year, month: comps.month, day: comps.day, hour: settings.targetBedtime.hour, minute: settings.targetBedtime.minute)),
              let wake = cal.date(from: DateComponents(year: comps.year, month: comps.month, day: comps.day, hour: settings.targetWake.hour, minute: settings.targetWake.minute)) else { return nil }
        return bed.addingTimeInterval(wake.timeIntervalSince(bed) / 2)
    }

    private func regularityPercent(_ arr: [SleepNight], settings: SleepSettings) -> Double {
        guard let t = targetMidpoint() else { return 0 }
        let tol = Double(settings.midpointToleranceMinutes) * 60.0
        let hits = arr.filter { n in
            guard let m = n.midpoint else { return false }
            return abs(m.timeIntervalSince(t)) <= tol
        }
        guard !arr.isEmpty else { return 0 }
        return Double(hits.count) / Double(arr.count) * 100.0
    }

    private func midpointStdDevMinutes(_ arr: [SleepNight]) -> Double {
        let mids = arr.compactMap { $0.midpoint?.timeIntervalSinceReferenceDate }
        guard mids.count > 1 else { return 0 }
        let mean = mids.reduce(0, +) / Double(mids.count)
        let variance = mids.map { pow($0 - mean, 2) }.reduce(0, +) / Double(mids.count)
        return sqrt(variance) / 60.0
    }

    func makeRecommendations(current: WeeklySummary, previous: WeeklySummary?) -> [Recommendation] {
        var recs: [Recommendation] = []
        if current.avgDurationMin < 420 {
            recs.append(.init(text: "Average sleep is under seven hours. Aim for a steady seven to eight hour window.", kind: .nudge))
        }
        if current.regularityPct < 70 {
            recs.append(.init(text: "Regularity is below seventy percent. Set a bedtime window and enable a gentle reminder.", kind: .nudge))
        }
        if current.socialJetlagHrs > 1.5 {
            recs.append(.init(text: "Weekend schedule shifts more than ninety minutes. Bring weekend and weekday midpoints closer.", kind: .warn))
        }
        if current.midpointStdDevMin > 60 {
            recs.append(.init(text: "Midpoint varies by more than an hour. Keep sleep and wake times steadier.", kind: .nudge))
        }
        if let prev = previous, current.regularityPct - prev.regularityPct >= 5 {
            recs.append(.init(text: "Good progress. Regularity improved week over week.", kind: .celebrate))
        }
        if recs.isEmpty { recs = [ .init(text: "Steady week. Keep your routine working for you.", kind: .celebrate) ] }
        return recs
    }

    // Helpers
    private func totalDuration(of samples: [HKCategorySample], category: HKCategoryValueSleepAnalysis) -> TimeInterval {
        samples.filter { $0.value == category.rawValue }
            .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
    }

    private func nightKey(for date: Date) -> String {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        if cal.component(.hour, from: date) < 12 {
            if let prev = cal.date(byAdding: .day, value: -1, to: cal.date(from: comps)!) {
                comps = cal.dateComponents([.year, .month, .day], from: prev)
            }
        }
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    private func dateFromNightKey(_ key: String) -> Date {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        var comps = DateComponents()
        comps.year = parts[0]; comps.month = parts[1]; comps.day = parts[2]
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func timeOn(date: Date, comps: DateComponents) -> Date? {
        let cal = Calendar.current
        let base = cal.dateComponents([.year, .month, .day], from: date)
        var c = DateComponents()
        c.year = base.year; c.month = base.month; c.day = base.day
        c.hour = comps.hour; c.minute = comps.minute
        return cal.date(from: c)
    }

    private func nightAnchor(for anyDate: Date) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: anyDate)
        comps.hour = 0; comps.minute = 0; comps.second = 0
        return cal.date(from: comps) ?? anyDate
    }

    private func upsert(night: SleepNight) {
        if let idx = nights.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: night.date) }) {
            nights[idx] = merge(old: nights[idx], new: night)
        } else {
            nights.append(night)
        }
    }

    private func merge(old: SleepNight, new: SleepNight) -> SleepNight {
        SleepNight(
            id: old.id,
            date: new.date,
            inBed: new.inBed ?? old.inBed,
            asleep: new.asleep ?? old.asleep,
            bedtime: new.bedtime ?? old.bedtime,
            wake: new.wake ?? old.wake,
            midpoint: new.midpoint ?? old.midpoint,
            efficiency: new.efficiency ?? old.efficiency,
            inferred: old.inferred || new.inferred
        )
    }

    private func sortNights() { nights.sort { $0.date > $1.date } }

    private func persist() {
        let anchorData = try? NSKeyedArchiver.archivedData(withRootObject: anchor as Any, requiringSecureCoding: true)
        store.save(nights: nights, settings: settings, anchorData: anchorData)
        lastUpdate = Date()
    }

    func resetAll() {
        nights = []
        anchor = nil
        store.reset()
        rebuildSummaries()
    }

    private func observeDayChange() {
        NotificationCenter.default.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: .main) { [weak self] _ in
            self?.recomputeAll()
        }
    }

    func recomputeAll() {
        rebuildSummaries()
    }

    // CSV + Notifications
    func exportCSV() -> URL? {
        let header = "dateISO,inBedMin,asleepMin,efficiency,midpointISO,bedtimeISO,wakeISO,inferred\n"
        let df = ISO8601DateFormatter()
        let rows = nights.sorted { $0.date < $1.date }.map { n -> String in
            let inBedMin = n.inBed.map { String(format: "%.1f", $0 / 60.0) } ?? "n/a"
            let asleepMin = n.asleep.map { String(format: "%.1f", $0 / 60.0) } ?? "n/a"
            let eff = n.efficiency.map { String(format: "%.3f", $0) } ?? "n/a"
            let mp = n.midpoint.map { df.string(from: $0) } ?? "n/a"
            let bt = n.bedtime.map { df.string(from: $0) } ?? "n/a"
            let wk = n.wake.map { df.string(from: $0) } ?? "n/a"
            return "\(df.string(from: n.date)),\(inBedMin),\(asleepMin),\(eff),\(mp),\(bt),\(wk),\(n.inferred)"
        }
        let csv = header + rows.joined(separator: "\n") + "\n"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sleep_export.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func scheduleBedtimeReminder() {
        guard settings.remindersEnabled,
              let bed = timeOn(date: Date(), comps: settings.targetBedtime)?.addingTimeInterval(-10 * 60) else { return }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: bed)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Gentle bedtime reminder"
        content.body = "Begin winding down for better sleep regularity."
        let req = UNNotificationRequest(identifier: "bedtime.reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}
