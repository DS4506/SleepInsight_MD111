
import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var vm: SleepVM

    var body: some View {
        List {
            Section(header: Text("Per night timeline")) {
                ForEach(vm.nights) { n in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(dateLabel(n.date)).font(.headline)
                            if n.inferred { Tag("inferred") }
                            Spacer()
                            if let e = n.efficiency {
                                Text("\(Int(e * 100))%").font(.subheadline).foregroundColor(Theme.good)
                            } else {
                                Text("n/a").font(.subheadline).foregroundColor(.white.opacity(0.6))
                            }
                        }
                        TimelineBar(night: n)
                            .frame(height: 18)
                        row("In bed", n.inBed)
                        row("Asleep", n.asleep)
                    }
                    .listRowBackground(Theme.secondary)
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.appBackground)
        .navigationTitle("Timeline")
    }

    private func row(_ label: String, _ value: TimeInterval?) -> some View {
        HStack {
            Text(label).font(.caption)
            Spacer()
            Text(value.map { String(format: "%.0f min", $0 / 60.0) } ?? "n/a").font(.caption)
        }
    }

    private func dateLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: d)
    }
}

private struct Tag: View {
    let text: String
    init(_ t: String) { text = t }
    var body: some View {
        Text(text)
            .font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
            .background(Theme.accent.opacity(0.2)).cornerRadius(6)
    }
}

private struct TimelineBar: View {
    let night: SleepNight
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let base: Date = {
                var c = Calendar.current
                var comps = c.dateComponents([.year, .month, .day], from: night.date)
                comps.hour = 18; comps.minute = 0
                return c.date(from: comps) ?? night.date
            }()
            let end = Calendar.current.date(byAdding: .hour, value: 14, to: base)!

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 9).fill(Theme.secondary.opacity(0.5))
                if let bt = night.bedtime, let wk = night.wake {
                    let startX = CGFloat(bt.timeIntervalSince(base) / end.timeIntervalSince(base)) * width
                    let endX = CGFloat(wk.timeIntervalSince(base) / end.timeIntervalSince(base)) * width
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Theme.warn.opacity(0.4))
                        .frame(width: max(0, endX - startX))
                        .position(x: (startX + endX)/2, y: 9)
                }
                if let asleep = night.asleep, let bt = night.bedtime {
                    let sleepEnd = bt.addingTimeInterval(asleep)
                    let startX = CGFloat(bt.timeIntervalSince(base) / end.timeIntervalSince(base)) * width
                    let endX = CGFloat(sleepEnd.timeIntervalSince(base) / end.timeIntervalSince(base)) * width
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Theme.accent.opacity(0.45))
                        .frame(width: max(0, endX - startX))
                        .position(x: (startX + endX)/2, y: 9)
                }
            }
        }
    }
}
