import Foundation
import Combine

@MainActor
final class CountdownViewModel: ObservableObject {
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var isRunning = false
    @Published private(set) var hasFinished = false

    let totalSeconds: Int
    private var timer: Timer?
    private var deadline: Date?

    init(minutes: Int) {
        let seconds = max(1, minutes) * 60
        totalSeconds = seconds
        remainingSeconds = seconds
    }

    /// Restore a previously saved focus session without losing its progress.
    init(totalSeconds: Int, remainingSeconds: Int) {
        self.totalSeconds = max(1, totalSeconds)
        self.remainingSeconds = max(0, min(self.totalSeconds, remainingSeconds))
    }

    var progress: Double { Double(totalSeconds - remainingSeconds) / Double(totalSeconds) }
    var clockText: String {
        String(format: "%d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    func start() {
        guard !isRunning, !hasFinished else { return }
        deadline = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    private func tick() {
        guard let deadline else { return }
        remainingSeconds = max(0, Int(ceil(deadline.timeIntervalSinceNow)))
        if remainingSeconds == 0 { finish() }
    }

    func pause() {
        guard isRunning else { return }
        tick()
        timer?.invalidate()
        timer = nil
        isRunning = false
        deadline = nil
    }

    func toggle() { isRunning ? pause() : start() }

    func finish() {
        guard !hasFinished else { return }
        timer?.invalidate()
        timer = nil
        isRunning = false
        deadline = nil
        remainingSeconds = 0
        hasFinished = true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        deadline = nil
    }
}

