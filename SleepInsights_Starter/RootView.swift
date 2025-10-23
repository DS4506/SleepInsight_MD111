import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Overview", systemImage: "rectangle.grid.2x2") }
            ChartsView().tabItem { Label("Charts", systemImage: "chart.bar.xaxis") }
            ConsistencyView().tabItem { Label("Consistency", systemImage: "metronome") }
            RecommendationsView().tabItem { Label("Tips", systemImage: "lightbulb") }
            DataPolicyView().tabItem { Label("Privacy", systemImage: "lock.shield") }
        }
    }
}
