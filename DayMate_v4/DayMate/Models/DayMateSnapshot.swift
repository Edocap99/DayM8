import Foundation

struct DayMateSnapshot: Codable {
    var exams: [StudyExam] = []
    var tasks: [DayTask] = []
    var mood: Mood? = nil
    var waterCount: Int = 0
    var waterDay: Date = Date()
    var lastCompletedStep: String? = nil
    // Optional for backward compatibility with v1 saved JSON. Existing data stays intact.
    var waterReminderPreferences: WaterReminderPreferences? = nil

    static func demo(now: Date = Date()) -> DayMateSnapshot {
        let calendar = Calendar.current
        let examDate = calendar.date(byAdding: .day, value: 14, to: now) ?? now
        let titles = ["Read notes Ch. 1", "Exercises 1–5", "Read Ch. 2",
                      "Exercises 6–10", "Mock test", "Review mistakes"]
        let steps = titles.enumerated().map { i, title in
            TinyStep(title: title, isCompleted: i < 2)
        }
        let exam = StudyExam(subject: "Math", date: examDate, steps: steps)
        func time(_ hour: Int, _ minute: Int) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
        }
        return DayMateSnapshot(
            exams: [exam],
            tasks: [
                DayTask(title: "Math · step 2", kind: .study, scheduledAt: time(9,30), durationMinutes: 25,
                        isCompleted: true, linkedStepID: steps[1].id),
                DayTask(title: "Math · step 3", kind: .study, scheduledAt: time(11,0), durationMinutes: 25,
                        linkedStepID: steps[2].id),
                DayTask(title: "Lab report", kind: .duty, scheduledAt: time(15,0), durationMinutes: 30),
                DayTask(title: "Gym", kind: .freeTime, scheduledAt: time(18,0), durationMinutes: 60),
                DayTask(title: "Dinner with friends", kind: .freeTime, scheduledAt: time(20,30), durationMinutes: 90)
            ],
            mood: nil,
            waterCount: 4,
            waterDay: now
        )
    }
}
