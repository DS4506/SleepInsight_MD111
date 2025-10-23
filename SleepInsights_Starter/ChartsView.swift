import SwiftUI

// STUDENT TODO — Plot duration (bars) + midpoint (points/line). Add tooltips or readable labels.

struct ChartsView: View {
    @EnvironmentObject var vm: SleepVM
    var body: some View {
        if vm.nights.isEmpty {
            ContentUnavailableView("No data to chart",
                                   systemImage: "chart.bar",
                                   description: Text("Load demo data from Privacy tab, then return here."))
        } else {
            List(vm.nights) { n in
                HStack {
                    Text(n.date, style: .date).frame(width: 120, alignment: .leading)
                    Text("Asleep: \(String(format: "%.1f h", (n.asleep ?? 0)/3600))")
                    Spacer()
                    Text(n.midpoint?.formatted(date: .omitted, time: .shortened) ?? "—")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
