import Foundation
import Combine

struct PairingSession: Codable {
    var sessionId: String
    var source: String
    var createdAt: Date
}

@MainActor
final class PairingStore: ObservableObject {
    @Published var current: PairingSession?
    private let defaultsKey = "checkin.pairing.session"

    init() {
        load()
    }

    func apply(sessionId: String, source: String) {
        current = PairingSession(sessionId: sessionId, source: source, createdAt: .now)
        save()
    }

    func clear() {
        current = nil
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }

    private func save() {
        guard let current else { return }
        if let data = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let session = try? JSONDecoder().decode(PairingSession.self, from: data)
        else { return }
        current = session
    }
}
