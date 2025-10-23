import SwiftUI

// STUDENT TODO — Build the 7‑day summary card (avg duration, midpoint, social jetlag, regularity, best/worst).

struct DashboardView: View {
    @EnvironmentObject var vm: SleepVM
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sleep Insights Dashboard").font(.title.bold())
                if let weekly = vm.makeWeeklySummary() {
                    GroupBox("Last 7 Days") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Avg Duration: \(String(format: "%.1f h", weekly.avgDurationMin / 60))")
                            Text("Avg Midpoint: \(weekly.avgMidpoint?.formatted(date: .omitted, time: .shortened) ?? "n/a")")
                            Text("Social Jetlag: \(String(format: "%.1f h", weekly.socialJetlagHrs))")
                            Text("Regularity: \(String(format: "%.0f%%", weekly.regularityPct))")
                            if let b = weekly.bestNight { Text("Best: \(b.date.formatted(date: .abbreviated, time: .omitted))") }
                            if let w = weekly.worstNight { Text("Needs love: \(w.date.formatted(date: .abbreviated, time: .omitted))") }
                        }
                    }
                    // TODO: Style with colors/emojis and accessibility labels
                } else {
                    ContentUnavailableView("Not enough data",
                                           systemImage: "bed.double",
                                           description: Text("Load demo data or add nights to see your summary."))
                }
            }
            .padding()
        }
    }
}
