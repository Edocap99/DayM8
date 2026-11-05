import Foundation

struct TinyStep: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool = false
}

struct StudyExam: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var subject: String
    var date: Date
    var steps: [TinyStep]

    var completedCount: Int { steps.filter(\.isCompleted).count }
    var progress: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(completedCount) / Double(steps.count)
    }
    var nextStep: TinyStep? { steps.first(where: { !$0.isCompleted }) }
    var nextStepIndex: Int? { steps.firstIndex(where: { !$0.isCompleted }) }
}

struct StudySelection {
    let exam: StudyExam
    let step: TinyStep
    let stepIndex: Int
}
