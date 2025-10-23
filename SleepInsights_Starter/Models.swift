import Foundation

struct SleepNight: Identifiable, Codable {
    var id: UUID = .init()
    var date: Date
    var inBed: TimeInterval?
    var asleep: TimeInterval?
    var bedtime: Date?
    var wake: Date?
    var midpoint: Date?
    var efficiency: Double?
}

struct SleepSettings: Codable {
    var targetBedtime: DateComponents
    var targetWake: DateComponents
    var midpointToleranceMinutes: Int = 45
    var remindersEnabled: Bool = false
}

struct WeeklySummary {
    let start: Date
    let end: Date
    let avgDurationMin: Double
    let avgMidpoint: Date?
    let socialJetlagHrs: Double
    let regularityPct: Double
    let midpointStdDevMin: Double
    let bestNight: SleepNight?
    let worstNight: SleepNight?
}

struct Recommendation: Identifiable {
    let id = UUID()
    let text: String
    let kind: Kind
    enum Kind { case celebrate, nudge, warn }
}
