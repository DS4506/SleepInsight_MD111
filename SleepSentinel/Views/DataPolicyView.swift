
import SwiftUI

struct DataPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Privacy and data").font(.title2).bold()
                Text("All data stays on device. The app reads HealthKit sleep analysis with your consent. It does not upload or share data. You can export a CSV that you control and you can reset the local cache at any time.")
                Text("The optional motion fusion uses on-device activity summaries to suggest sleep onset and wake. These are labeled as inferred and you can ignore them.")
            }
            .padding()
        }
        .navigationTitle("Data Policy")
        .background(Theme.appBackground)
        .foregroundStyle(.white)
    }
}
