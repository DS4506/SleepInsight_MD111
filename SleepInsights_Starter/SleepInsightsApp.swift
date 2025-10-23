import SwiftUI

@main
struct SleepInsightsApp: App {
    @StateObject private var vm = SleepVM()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(vm)
                .onAppear { if vm.nights.isEmpty { vm.loadDemoData() } }
        }
    }
}
