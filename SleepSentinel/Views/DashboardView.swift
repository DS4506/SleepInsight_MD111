
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var vm: SleepVM

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                if let w = vm.weeklyNow {
                    SummaryCard(title: "This Week", summary: w).themedCard()
                }
                if let p = vm.weeklyPrev {
                    SummaryCard(title: "Last Week", summary: p).themedCard()
                }
                if !vm.recommendations.isEmpty {
                    recsCard.themedCard()
                }
                TrendsMiniChart(nights: vm.nights).themedCard()
            }
            .padding()
        }
        .navigationTitle("SleepSentinel")
        .foregroundStyle(.white)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Trends").font(.title2).bold()
                if let ts = vm.lastUpdate {
                    Text("Updated \(relative(ts))").font(.footnote).foregroundColor(.white.opacity(0.7))
                }
            }
            Spacer()
        }
    }

    private func relative(_ d: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: d, relativeTo: Date())
    }

    private var recsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommendations").font(.headline)
            ForEach(vm.recommendations) { r in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: icon(for: r.kind))
                        .foregroundColor(color(for: r.kind))
                    Text(r.text)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(10)
                .background(Theme.secondary.opacity(0.35))
                .cornerRadius(10)
            }
        }
    }

    private func icon(for kind: Recommendation.Kind) -> String {
        switch kind { case .celebrate: return "sparkles"; case .nudge: return "lightbulb"; case .warn: return "exclamationmark.triangle" }
    }
    private func color(for kind: Recommendation.Kind) -> Color {
        switch kind { case .celebrate: return Theme.good; case .nudge: return Theme.accent; case .warn: return Theme.alert }
    }
}

private struct SummaryCard: View {
    let title: String
    let summary: WeeklySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundColor(.white)
            Grid(horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow { row("Avg duration", "\(Int(summary.avgDurationMin)) min") }
                GridRow { row("Social jetlag", String(format: "%.1f h", summary.socialJetlagHrs)) }
                GridRow { row("Regularity", String(format: "%.0f%%", summary.regularityPct)) }
                GridRow { row("Midpoint SD", String(format: "%.0f min", summary.midpointStdDevMin)) }
            }
        }
    }

    private func row(_ a: String, _ b: String) -> some View {
        HStack {
            Text(a).foregroundColor(.white.opacity(0.85))
            Spacer()
            Text(b).foregroundColor(.white)
        }.font(.subheadline)
    }
}

private struct TrendsMiniChart: View {
    let nights: [SleepNight]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration and midpoint").font(.headline).foregroundColor(.white)
            GeometryReader { geo in
                let maxMin = max(30.0, nights.compactMap { $0.asleep?.rounded() }.map { $0/60.0 }.max() ?? 0)
                let w = geo.size.width
                let h = geo.size.height
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.secondary.opacity(0.4))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    ForEach(Array(nights.enumerated()), id: \.offset) { idx, n in
                        let x = CGFloat(idx) / CGFloat(max(nights.count - 1, 1)) * (w - 8) + 4
                        let durMin = (n.asleep ?? 0) / 60.0
                        let barH = CGFloat(durMin / maxMin) * (h - 24)

                        Path { p in
                            p.addRoundedRect(in: CGRect(x: x - 6, y: h - barH - 8, width: 12, height: barH), cornerSize: CGSize(width: 4, height: 4))
                        }
                        .fill(Theme.accent.opacity(0.45))

                        if let mp = n.midpoint {
                            let hour = Calendar.current.component(.hour, from: mp)
                            let y = CGFloat(hour) / 24.0 * (h - 24) + 8
                            Circle().frame(width: 7, height: 7)
                                .foregroundColor(.white)
                                .overlay(Circle().stroke(Theme.accent, lineWidth: 2))
                                .position(x: x, y: y)
                                .accessibilityLabel("Midpoint \(hour):00")
                        }
                    }
                }
            }
            .frame(height: 180)
        }
    }
}
