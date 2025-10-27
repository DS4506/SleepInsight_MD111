
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: SleepVM
    @Binding var showExportSheet: Bool
    @Binding var exportURL: URL?

    var body: some View {
        Form {
            Section(header: Text("Targets")) {
                TimePickerRow(title: "Target bedtime", components: $vm.settings.targetBedtime)
                TimePickerRow(title: "Target wake", components: $vm.settings.targetWake)
                Stepper("Midpoint tolerance \(vm.settings.midpointToleranceMinutes) min",
                        value: $vm.settings.midpointToleranceMinutes, in: 15...120, step: 5)
            }
            Section(header: Text("Permissions")) {
                Toggle("Enable reminders", isOn: $vm.settings.remindersEnabled)
                    .onChange(of: vm.settings.remindersEnabled) { _, on in
                        if on { vm.requestNotificationPermission(); vm.scheduleBedtimeReminder() }
                    }
                Button("Re-request Health permissions") {
                    Task { await vm.requestPermissions() }
                }
            }
            Section(header: Text("Data")) {
                Button("Run motion fusion once") { vm.runMotionFusion() }
                Button("Export CSV") {
                    exportURL = vm.exportCSV()
                    showExportSheet = exportURL != nil
                }
                Button("Reset local cache", role: .destructive) { vm.resetAll() }
            }
            Section(header: Text("Privacy")) {
                NavigationLink("Data policy") { DataPolicyView() }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.appBackground)
        .navigationTitle("Settings")
        .tint(Theme.accent)
    }
}

private struct TimePickerRow: View {
    let title: String
    @Binding var components: DateComponents

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            DatePicker("",
                       selection: Binding(
                        get: {
                            var base = Date()
                            if let h = components.hour, let m = components.minute {
                                base = Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
                            }
                            return base
                        },
                        set: { newValue in
                            let h = Calendar.current.component(.hour, from: newValue)
                            let m = Calendar.current.component(.minute, from: newValue)
                            components.hour = h
                            components.minute = m
                        }),
                       displayedComponents: .hourAndMinute)
            .labelsHidden()
        }
    }
}
