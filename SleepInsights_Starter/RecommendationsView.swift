import SwiftUI

// STUDENT TODO — 2–4 adaptive messages with styles (celebrate/nudge/warn).

struct RecommendationsView: View {
    @EnvironmentObject var vm: SleepVM
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personalized Recommendations").font(.title2.bold())
            if let cur = vm.makeWeeklySummary() {
                let prev = vm.makeWeeklySummary(startIndex: 7)
                let recs = vm.makeRecommendations(current: cur, previous: prev)
                ForEach(recs) { r in
                    HStack(alignment: .top, spacing: 8) {
                        Text(icon(for: r.kind))
                        Text(r.text)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(background(for: r.kind))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                ContentUnavailableView("No recommendations yet",
                                       systemImage: "lightbulb",
                                       description: Text("Add more nights to unlock insights."))
            }
            Spacer()
        }
        .padding()
    }
    func icon(for kind: Recommendation.Kind) -> String {
        switch kind { case .celebrate: return "🎉"; case .nudge: return "💡"; case .warn: return "⚠️" }
    }
    @ViewBuilder
    func background(for kind: Recommendation.Kind) -> some View {
        switch kind { case .celebrate: Color.green.opacity(0.12)
            case .nudge: Color.yellow.opacity(0.12)
            case .warn: Color.red.opacity(0.12) }
    }
}
