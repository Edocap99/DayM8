import Foundation
import Combine

/// Saved separately from DayMateSnapshot to preserve all existing exam data.
struct StudyFocusSession: Codable, Equatable {
    let examID: UUID
    let stepID: UUID
    let totalSeconds: Int
    var remainingSeconds: Int
}

@MainActor
final class DayMateStore: ObservableObject {
    @Published private(set) var snapshot: DayMateSnapshot {
        didSet { repository.save(snapshot) }
    }
    private let repository: any DayMateRepository
    private static let focusStorageKey = "daymate.focusSessions.v1"

    @Published private(set) var focusSessions: [UUID: StudyFocusSession] = [:] {
        didSet {
            guard let encoded = try? JSONEncoder().encode(focusSessions) else { return }
            UserDefaults.standard.set(encoded, forKey: Self.focusStorageKey)
        }
    }

    init(repository: any DayMateRepository = UserDefaultsDayMateRepository()) {
        self.repository = repository
        self.snapshot = repository.load() ?? DayMateSnapshot()
        if let data = UserDefaults.standard.data(forKey: Self.focusStorageKey),
           let restored = try? JSONDecoder().decode([UUID: StudyFocusSession].self, from: data) {
            self.focusSessions = restored
        }
    }

    // MARK: - Persistent focus sessions (one per tiny step)

    func focusSession(for examID: UUID) -> StudyFocusSession? {
        guard let next = selection(for: examID),
              let session = focusSessions[next.step.id],
              session.examID == examID,
              session.remainingSeconds > 0 else { return nil }
        return session
    }

    /// Called only after choosing a mood for a new session.
    func beginFocus(examID: UUID, minutes: Int) {
        guard minutes > 0, let current = selection(for: examID) else { return }
        if focusSession(for: examID) != nil { return } // Never reset an unfinished session.
        let seconds = minutes * 60
        focusSessions[current.step.id] = StudyFocusSession(
            examID: examID,
            stepID: current.step.id,
            totalSeconds: seconds,
            remainingSeconds: seconds
        )
    }

    func saveFocus(examID: UUID, stepID: UUID, remainingSeconds: Int) {
        guard let session = focusSessions[stepID],
              session.examID == examID else { return }
        let value = max(0, min(session.totalSeconds, remainingSeconds))
        guard value != session.remainingSeconds else { return }
        focusSessions[stepID]?.remainingSeconds = value
    }

    func focusButtonTitle(for examID: UUID) -> String {
        guard let session = focusSession(for: examID) else { return "Start" }
        let seconds = session.remainingSeconds
        if seconds % 60 == 0 {
            return "Resume · \(seconds / 60) min"
        }
        return String(format: "Resume · %d:%02d", seconds / 60, seconds % 60)
    }

    var sortedExams: [StudyExam] { snapshot.exams.sorted { $0.date < $1.date } }
    var nextSelection: StudySelection? {
        for exam in sortedExams {
            if let stepIndex = exam.nextStepIndex {
                return StudySelection(exam: exam, step: exam.steps[stepIndex], stepIndex: stepIndex)
            }
        }
        return nil
    }
    func exam(id: UUID) -> StudyExam? { snapshot.exams.first { $0.id == id } }
    func selection(for examID: UUID) -> StudySelection? {
        guard let exam = exam(id: examID), let index = exam.nextStepIndex else { return nil }
        return StudySelection(exam: exam, step: exam.steps[index], stepIndex: index)
    }

    func addExam(subject: String, date: Date, stepTitles: [String]) {
        let titles = stepTitles.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let cleanedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedSubject.isEmpty, !titles.isEmpty else { return }
        snapshot.exams.append(StudyExam(subject: cleanedSubject, date: date,
                                         steps: titles.map { TinyStep(title: $0) }))
    }

    /// Permanently removes an exam and any planner entries actually linked to
    /// its steps. Independent study, duty and free-time tasks are preserved.
    func deleteExam(id: UUID) {
        guard let exam = snapshot.exams.first(where: { $0.id == id }) else { return }
        let removedStepIDs = Set(exam.steps.map(\.id))
        snapshot.exams.removeAll { $0.id == id }
        for stepID in removedStepIDs { focusSessions.removeValue(forKey: stepID) }
        let deletedTasks = snapshot.tasks.filter { task in
            task.linkedStepID.map { removedStepIDs.contains($0) } ?? false
        }
        snapshot.tasks.removeAll { task in
            task.linkedStepID.map { removedStepIDs.contains($0) } ?? false
        }
        for task in deletedTasks { ActivityReminderService().cancel(id: task.id) }
        if let lastStep = snapshot.lastCompletedStep,
           exam.steps.contains(where: { $0.title == lastStep }) {
            snapshot.lastCompletedStep = nil
        }
    }

    func setStepCompleted(examID: UUID, stepID: UUID, completed: Bool) {
        guard let ei = snapshot.exams.firstIndex(where: { $0.id == examID }),
              let si = snapshot.exams[ei].steps.firstIndex(where: { $0.id == stepID }) else { return }
        snapshot.exams[ei].steps[si].isCompleted = completed
        if completed { focusSessions.removeValue(forKey: stepID) }
        for i in snapshot.tasks.indices where snapshot.tasks[i].linkedStepID == stepID {
            snapshot.tasks[i].isCompleted = completed
            updateReminderForTask(snapshot.tasks[i])
        }
    }

    func completeCurrentStep(examID: UUID) {
        guard let current = selection(for: examID) else { return }
        setStepCompleted(examID: examID, stepID: current.step.id, completed: true)
        snapshot.lastCompletedStep = current.step.title
    }

    func completeFocus(examID: UUID, stepID: UUID) {
        guard let exam = exam(id: examID),
              let step = exam.steps.first(where: { $0.id == stepID }) else { return }
        setStepCompleted(examID: examID, stepID: stepID, completed: true)
        snapshot.lastCompletedStep = step.title
    }

    /// Keep the chapter insertion and task deletion added after v4.
    func addChapter(examID: UUID, title: String) {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty,
              let index = snapshot.exams.firstIndex(where: { $0.id == examID }) else { return }
        snapshot.exams[index].steps.append(TinyStep(title: cleaned))
    }

    func deleteTask(id: UUID) {
        snapshot.tasks.removeAll { $0.id == id }
        ActivityReminderService().cancel(id: id)
    }

    func saveMood(_ mood: Mood) { snapshot.mood = mood }

    func tasks(for day: Date) -> [DayTask] {
        snapshot.tasks.filter { Calendar.current.isDate($0.scheduledAt, inSameDayAs: day) }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    /// The caller asks iOS for authorization BEFORE setting remindAtStart = true.
    /// Return the newly saved activity to schedule its one-time notification.
    @discardableResult
    func addTask(
        title: String,
        kind: TaskKind,
        at date: Date,
        duration: Int,
        remindAtStart: Bool = false
    ) -> DayTask? {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        let task = DayTask(
            title: cleaned,
            kind: kind,
            scheduledAt: date,
            durationMinutes: duration,
            remindAtStart: remindAtStart
        )
        snapshot.tasks.append(task)
        return task
    }

    /// If scheduling fails or permission is denied, retain the task but do not
    /// claim to have configured its notification.
    func setTaskReminder(id: UUID, enabled: Bool) {
        guard let i = snapshot.tasks.firstIndex(where: { $0.id == id }) else { return }
        snapshot.tasks[i].remindAtStart = enabled
        if !enabled { ActivityReminderService().cancel(id: id) }
    }

    func toggleTask(id: UUID) {
        guard let i = snapshot.tasks.firstIndex(where: { $0.id == id }) else { return }
        let nextValue = !snapshot.tasks[i].isCompleted
        if let linkedID = snapshot.tasks[i].linkedStepID,
           let exam = snapshot.exams.first(where: { $0.steps.contains(where: { $0.id == linkedID }) }) {
            setStepCompleted(examID: exam.id, stepID: linkedID, completed: nextValue)
        } else {
            snapshot.tasks[i].isCompleted = nextValue
            updateReminderForTask(snapshot.tasks[i])
        }
    }

    private func updateReminderForTask(_ task: DayTask) {
        let service = ActivityReminderService()
        if task.isCompleted || !task.hasStartReminder || task.scheduledAt <= Date() {
            service.cancel(id: task.id)
        } else {
            Task {
                // Re-activate a future reminder if a completion was undone.
                try? await service.schedule(task)
            }
        }
    }

    func reconcileActivityReminders() async {
        await ActivityReminderService().reconcile(with: snapshot.tasks)
    }

    var todayWaterCount: Int {
        Calendar.current.isDate(snapshot.waterDay, inSameDayAs: Date()) ? snapshot.waterCount : 0
    }
    func setWaterCount(_ count: Int) {
        snapshot.waterDay = Date()
        snapshot.waterCount = min(8, max(0, count))
    }

    var waterReminderPreferences: WaterReminderPreferences {
        snapshot.waterReminderPreferences ?? .default
    }

    func setWaterReminderPreferences(_ preferences: WaterReminderPreferences) {
        snapshot.waterReminderPreferences = preferences
    }

}

