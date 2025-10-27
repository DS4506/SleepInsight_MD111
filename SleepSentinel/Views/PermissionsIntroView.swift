
import SwiftUI

struct PermissionsIntroView: View {
    var requestHealth: () -> Void
    var requestNotifications: () -> Void

    var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Welcome to SleepSentinel")
                        .font(.title2).bold().foregroundColor(.white)
                    Text("We ask for read access to your Health sleep analysis. Reminders are optional.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                }
                Button(action: requestHealth) {
                    Text("Allow Health access").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)

                Button(action: requestNotifications) {
                    Text("Enable reminders").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Spacer().frame(height: 8)
            }
            .padding()
        }
    }
}
