import Foundation

protocol DayMateRepository {
    func load() -> DayMateSnapshot?
    func save(_ snapshot: DayMateSnapshot)
}

struct UserDefaultsDayMateRepository: DayMateRepository {
    private let key = "daymate.snapshot.v1"

    func load() -> DayMateSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(DayMateSnapshot.self, from: data)
    }

    func save(_ snapshot: DayMateSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
