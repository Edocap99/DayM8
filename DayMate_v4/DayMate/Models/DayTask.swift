import Foundation

enum TaskKind: String, CaseIterable, Codable, Identifiable {
    case study = "Study"
    case duty = "Duty"
    case freeTime = "Free time"

    var id: Self { self }
    var symbol: String {
        switch self {
        case .study: return "book.closed.fill"
        case .duty: return "cup.and.saucer"
        case .freeTime: return "figure.walk"
        }
    }
}

struct DayTask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var kind: TaskKind
    var scheduledAt: Date
    var durationMinutes: Int
    var isCompleted: Bool = false
    var linkedStepID: UUID? = nil
    // Optional to decode activities saved before notifications were introduced.
    // Old entries keep working and do not start producing unexpected alerts.
    var remindAtStart: Bool? = nil

    var hasStartReminder: Bool { remindAtStart == true }
}

