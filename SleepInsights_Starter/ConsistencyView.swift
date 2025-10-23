import SwiftUI

// STUDENT TODO — Show midpoint std dev (±min) and regularity %. Optional sparkline.

struct ConsistencyView: View {
    @EnvironmentObject var vm: SleepVM
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consistency Analyzer").font(.title2.bold())
            if let weekly = vm.makeWeeklySummary() {
                GroupBox("This Week") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Midpoint variability: ±\(String(format: "%.0f", weekly.midpointStdDevMin)) min")
                        Text("Regularity: \(String(format: "%.0f%%", weekly.regularityPct)) (±\(vm.settings.midpointToleranceMinutes) min window)")
                    }
                }
            } else {
                ContentUnavailableView("Consistency unavailable",
                                       systemImage: "metronome",
                                       description: Text("Need at least a few nights to compute variability and regularity."))
            }
            Spacer()
        }
        .padding()
    }
}
