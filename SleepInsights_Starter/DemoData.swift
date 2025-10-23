import Foundation

struct DemoSegment: Codable { let type: String; let start: Date; let end: Date }
struct DemoNight: Codable { let segments: [DemoSegment] }

enum DemoData {
    static func load() -> [SleepNight] {
        if let url = Bundle.main.url(forResource: "sleep_demo", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let nights = try? JSONDecoder.iso8601.decode([DemoNight].self, from: data) {
            return nightsToSleepNights(nights)
        }
        return []
    }
    private static func nightsToSleepNights(_ src: [DemoNight]) -> [SleepNight] {
        let cal = Calendar.current
        var results: [SleepNight] = []
        for dn in src {
            let inBedDur = dn.segments.filter { $0.type == "inBed" }
                .reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }
            let asleepDur = dn.segments.filter { $0.type == "asleep" }
                .reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }
            let bedtime = dn.segments.map { $0.start }.min()
            let wake = dn.segments.map { $0.end }.max()
            let midpoint = (bedtime != nil && asleepDur > 0) ? bedtime!.addingTimeInterval(asleepDur/2) : nil
            let comps = cal.dateComponents([.year, .month, .day], from: bedtime ?? Date())
            let anchor = cal.date(from: comps) ?? Date()
            results.append(SleepNight(date: anchor,
                                      inBed: inBedDur,
                                      asleep: asleepDur,
                                      bedtime: bedtime,
                                      wake: wake,
                                      midpoint: midpoint,
                                      efficiency: inBedDur > 0 ? asleepDur / inBedDur : nil))
        }
        return results.sorted { $0.date > $1.date } // newest first
    }
}

extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
