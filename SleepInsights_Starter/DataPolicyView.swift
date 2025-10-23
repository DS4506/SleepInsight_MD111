import SwiftUI

// STUDENT TODO — Explain local-only data, provide Export CSV + Reset buttons.

struct DataPolicyView: View {
    @EnvironmentObject var vm: SleepVM
    @State private var shareURL: URL? = nil
    @State private var showShare = false
    var body: some View {
        Form {
            Section("Data Policy") {
                Text("All data is local. You choose when to export. Reset clears local cache (not Apple Health).")
            }
            Section("Export") {
                Button("Export Weekly CSV") {
                    shareURL = vm.exportWeeklyCSV()
                    showShare = shareURL != nil
                }
            }
            Section("Reset") {
                Button("Reset Local Data", role: .destructive) {
                    vm.nights.removeAll()
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let url = shareURL { ShareLink(item: url) }
        }
    }
}
