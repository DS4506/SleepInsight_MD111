
import SwiftUI

@main
struct SleepSentinelApp: App {
    @StateObject private var vm = SleepVM()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(vm)
                .onAppear { vm.bootstrap() }
                .tint(Theme.accent)
        }
    }
}
