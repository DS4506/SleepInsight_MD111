
import SwiftUI

struct ConsistencyView: View {
    @EnvironmentObject var vm: SleepVM

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let s = vm.weeklyNow {
                    ConsistencyCard(summary: s).themedCard()
                }
                ChronotypeCard(nights: vm.nights).themedCard()
                CorrelationHint().themedCard()
            }
            .padding()
        }
        .navigationTitle("Consistency")
        .foregroundStyle(.white)
        .background(Theme.appBackground)
    }
}

private struct ConsistencyCard: View {
    let summary: WeeklySummary
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Seven day window").font(.headline).foregroundColor(.white)
            Text("Regularity \(String(format: "%.0f%%", summary.regularityPct))")
            Text("Social jetlag \(String(format: "%.1f h", summary.socialJetlagHrs))")
            Text("Midpoint standard deviation \(String(format: "%.0f min", summary.midpointStdDevMin))")
            if let best = summary.bestNight?.asleep {
                Text("Best night \(String(format: "%.0f min asleep", best/60.0))")
            }
        }
        .foregroundColor(.white.opacity(0.9))
    }
}

private struct ChronotypeCard: View {
    let nights: [SleepNight]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chronotype trend").font(.headline).foregroundColor(.white)
            Text(label(for: averageMidpoint()))
                .foregroundColor(.white.opacity(0.9))
        }
    }
    private func averageMidpoint() -> Double {
        let mids = nights.compactMap { $0.midpoint }.map { Calendar.current.component(.hour, from: $0) }
        guard !mids.isEmpty else { return 12 }
        return Double(mids.reduce(0, +)) / Double(mids.count)
    }
    private func label(for hour: Double) -> String {
        if hour < 2 || hour >= 22 { return "Evening type" }
        if hour < 6 { return "Late type" }
        if hour < 10 { return "Intermediate type" }
        return "Early type"
    }
}

private struct CorrelationHint: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Idea for later").font(.headline).foregroundColor(.white)
            Text("Compare sleep with steps or phone use as an extension.")
                .foregroundColor(.white.opacity(0.9))
        }
    }
}
