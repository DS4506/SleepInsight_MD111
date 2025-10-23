import Foundation
import SwiftUI

@MainActor
final class SleepVM: ObservableObject {
    @Published var nights: [SleepNight] = []
    @Published var settings = SleepSettings(targetBedtime: .init(hour: 23, minute: 0),
                                            targetWake: .init(hour: 7, minute: 0))
    @Published var usingDemo = false
    
    func makeWeeklySummary(windowDays: Int = 7, startIndex: Int = 0) -> WeeklySummary? {
        guard !nights.isEmpty else { return nil }
        let slice = Array(nights.dropFirst(startIndex).prefix(windowDays))
        guard !slice.isEmpty else { return nil }
        let avgDur = avgDurationMin(of: slice)
        let avgMid = avgMidpoint(slice)
        let sj = socialJetlagHours(slice)
        let reg = regularityPercent(slice, settings: settings)
        let std = midpointStdDevMin(slice)
        let best = slice.max(by: { ($0.asleep ?? 0) < ($1.asleep ?? 0) })
        let worst = slice.min(by: { ($0.asleep ?? 0) < ($1.asleep ?? 0) })
        return WeeklySummary(start: slice.last!.date,
                             end: slice.first!.date,
                             avgDurationMin: avgDur,
                             avgMidpoint: avgMid,
                             socialJetlagHrs: sj,
                             regularityPct: reg,
                             midpointStdDevMin: std,
                             bestNight: best,
                             worstNight: worst)
    }
    
    func avgDurationMin(of nights: [SleepNight]) -> Double {
        let mins = nights.compactMap { $0.asleep.map { $0/60.0 } }
        guard !mins.isEmpty else { return 0 }
        return mins.reduce(0, +) / Double(mins.count)
    }
    func avgMidpoint(_ nights: [SleepNight]) -> Date? {
        let mids = nights.compactMap { $0.midpoint }
        guard !mids.isEmpty else { return nil }
        let t = mids.map{ $0.timeIntervalSinceReferenceDate }.reduce(0,+) / Double(mids.count)
        return Date(timeIntervalSinceReferenceDate: t)
    }
    func socialJetlagHours(_ nights: [SleepNight]) -> Double {
        let cal = Calendar.current
        let wkd = nights.compactMap { n in cal.isDateInWeekend(n.date) ? n.midpoint : nil }
        let wk  = nights.compactMap { n in !cal.isDateInWeekend(n.date) ? n.midpoint : nil }
        guard !wkd.isEmpty, !wk.isEmpty,
              let aw = avgMidpoint(wk), let ae = avgMidpoint(wkd) else { return 0 }
        return abs(aw.timeIntervalSince(ae)) / 3600.0
    }
    func targetMidpointDate(_ s: SleepSettings, on ref: Date = Date()) -> Date? {
        let cal = Calendar.current
        let y = cal.component(.year, from: ref), m = cal.component(.month, from: ref), d = cal.component(.day, from: ref)
        guard let bed = cal.date(from: DateComponents(year: y, month: m, day: d, hour: s.targetBedtime.hour, minute: s.targetBedtime.minute)),
              let wake = cal.date(from: DateComponents(year: y, month: m, day: d, hour: s.targetWake.hour, minute: s.targetWake.minute))
        else { return nil }
        return bed + wake.timeIntervalSince(bed)/2
    }
    func regularityPercent(_ nights: [SleepNight], settings: SleepSettings) -> Double {
        guard let target = targetMidpointDate(settings) else { return 0 }
        let tol = Double(settings.midpointToleranceMinutes) * 60.0
        let hits = nights.filter { n in
            guard let m = n.midpoint else { return false }
            return abs(m.timeIntervalSince(target)) <= tol
        }.count
        return nights.isEmpty ? 0 : (Double(hits) / Double(nights.count) * 100.0)
    }
    func midpointStdDevMin(_ nights: [SleepNight]) -> Double {
        let mids = nights.compactMap { $0.midpoint?.timeIntervalSinceReferenceDate }
        guard mids.count > 1 else { return 0 }
        let mean = mids.reduce(0,+) / Double(mids.count)
        let varSum = mids.reduce(0) { $0 + pow($1 - mean, 2) }
        let variance = varSum / Double(mids.count)
        return sqrt(variance) / 60.0
    }
    
    func makeRecommendations(current: WeeklySummary, previous: WeeklySummary?) -> [Recommendation] {
        var recs: [Recommendation] = []
        if current.avgDurationMin < 420 {
            recs.append(.init(text: "You averaged under 7 hours. Try a consistent 7–8h window this week.", kind: .nudge))
        }
        if current.regularityPct < 70 {
            recs.append(.init(text: "Regularity below 70%. Pick a bedtime window and set a gentle reminder.", kind: .nudge))
        }
        if current.socialJetlagHrs > 1.5 {
            recs.append(.init(text: "Weekend shifts exceed 1.5h. Align weekend and weekday bedtimes to reduce social jetlag.", kind: .warn))
        }
        if current.midpointStdDevMin > 60 {
            recs.append(.init(text: "Your midpoint varies more than 1 hour. Aim for steadier sleep/wake times.", kind: .nudge))
        }
        if let prev = previous, current.regularityPct - prev.regularityPct >= 5 {
            recs.append(.init(text: "Nice! Your regularity improved this week 🎉", kind: .celebrate))
        }
        return recs.isEmpty ? [ .init(text: "Steady week. Keep what works!", kind: .celebrate) ] : recs
    }
    
    func loadDemoData() {
        nights = DemoData.load()
        usingDemo = true
    }
    
    func exportWeeklyCSV() -> URL? {
        guard let cur = makeWeeklySummary() else { return nil }
        let header = "weekStartISO,weekEndISO,avgDurationMin,avgMidpointISO,socialJetlagHrs,regularityPct,midpointStdDevMin\n"
        let df = ISO8601DateFormatter()
        let row = "\(df.string(from: cur.start)),\(df.string(from: cur.end)),\(cur.avgDurationMin),\(cur.avgMidpoint.map(df.string) ?? ""),\(cur.socialJetlagHrs),\(cur.regularityPct),\(cur.midpointStdDevMin)\n"
        let csv = header + row
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sleep_weekly.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
