
import Foundation

struct PersistedPayload: Codable {
    var nights: [SleepNight]
    var settings: SleepSettings
    var lastAnchorData: Data?
}

final class SleepStore {
    static let shared = SleepStore()

    private var url: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("sleep_cache.json")
    }

    func load() -> PersistedPayload? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PersistedPayload.self, from: data)
    }

    func save(nights: [SleepNight], settings: SleepSettings, anchorData: Data?) {
        let payload = PersistedPayload(nights: nights, settings: settings, lastAnchorData: anchorData)
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func reset() {
        try? FileManager.default.removeItem(at: url)
    }
}
