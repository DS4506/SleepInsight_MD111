
import SwiftUI

struct RootView: View {
    @EnvironmentObject var vm: SleepVM
    @State private var showExportSheet = false
    @State private var exportURL: URL? = nil

    var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()
            NavigationStack {
                if vm.hkAuthorized {
                    TabView {
                        DashboardView()
                            .tabItem { Label("Trends", systemImage: "chart.bar.fill") }
                        TimelineView()
                            .tabItem { Label("Timeline", systemImage: "rectangle.split.3x1") }
                        ConsistencyView()
                            .tabItem { Label("Consistency", systemImage: "target") }
                        SettingsView(showExportSheet: $showExportSheet, exportURL: $exportURL)
                            .tabItem { Label("Settings", systemImage: "gearshape") }
                    }
                } else {
                    PermissionsIntroView(
                        requestHealth: { Task { await vm.requestPermissions() } },
                        requestNotifications: { vm.requestNotificationPermission() }
                    )
                }
            }
        }
        .sheet(isPresented: $showExportSheet, onDismiss: { exportURL = nil }) {
            if let url = exportURL { ShareSheet(items: [url]) }
        }
        .task {
            if !vm.hkAuthorized { await vm.requestPermissions() }
        }
    }
}
