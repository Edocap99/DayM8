import SwiftUI

struct FocusTimerView: View {
    @EnvironmentObject private var store: DayMateStore
    @Environment(\.scenePhase) private var scenePhase
    let examID: UUID
    let stepID: UUID
    let onHome: () -> Void
    let onFinished: () -> Void
    @StateObject private var countdown: CountdownViewModel

    init(examID: UUID, stepID: UUID, totalSeconds: Int,
         remainingSeconds: Int, onHome: @escaping () -> Void,
         onFinished: @escaping () -> Void) {
        self.examID = examID
        self.stepID = stepID
        self.onHome = onHome
        self.onFinished = onFinished
        _countdown = StateObject(wrappedValue: CountdownViewModel(
            totalSeconds: totalSeconds,
            remainingSeconds: remainingSeconds
        ))
    }

    var body: some View {
        ZStack {
            DayMateBackground()
            VStack(spacing: 18) {
                HStack {
                    Button("‹ Home", action: leaveAndSave)
                        .font(.system(size: 14))
                        .foregroundStyle(DayMateTheme.secondary)
                    Spacer()
                }
                Spacer()
                if let selection = store.selection(for: examID) {
                    Text("\(selection.exam.subject) · step \(selection.stepIndex + 1) of \(selection.exam.steps.count)")
                        .font(.system(size: 13))
                        .foregroundStyle(DayMateTheme.secondary)
                    Text(selection.step.title)
                        .font(.system(size: 27, weight: .bold))
                        .multilineTextAlignment(.center)
                } else {
                    Text("Focus time").font(.system(size: 27, weight: .bold))
                }
                ZStack {
                    Circle().stroke(DayMateTheme.purple.opacity(0.35), lineWidth: 1)
                        .frame(width: 295, height: 295)
                    Circle().stroke(DayMateTheme.green.opacity(0.42), lineWidth: 1)
                        .frame(width: 253, height: 253)
                    Circle().stroke(DayMateTheme.surfaceLight, lineWidth: 12)
                        .frame(width: 198, height: 198)
                    Circle()
                        .trim(from: 0, to: countdown.progress)
                        .stroke(DayMateTheme.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 198, height: 198)
                    VStack(spacing: 3) {
                        Image("MascotStudying")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 128, height: 128)
                            .accessibilityHidden(true)

                        Text(countdown.clockText)
                            .font(.system(size: 39, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                    .offset(y: 8)
                }
                .frame(height: 340)
                Spacer()
                Text("Phone down, one tiny step.")
                    .font(.system(size: 14))
                    .foregroundStyle(DayMateTheme.secondary)
                HStack(spacing: 52) {
                    Button {
                        countdown.toggle()
                        if !countdown.isRunning { checkpoint() }
                    } label: {
                        Image(systemName: countdown.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(DayMateTheme.surfaceLight, in: Circle())
                    }
                    .accessibilityLabel(countdown.isRunning ? "Pause" : "Resume")
                    Button { countdown.finish() } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(DayMateTheme.background)
                            .frame(width: 56, height: 56)
                            .background(DayMateTheme.green, in: Circle())
                    }
                    .accessibilityLabel("Finish tiny step")
                }
                .buttonStyle(.plain)
                Spacer(minLength: 65)
            }
            .padding(.horizontal, 23)
            .padding(.top, 18)
        }
        .onAppear { countdown.start() }
        .onDisappear {
            countdown.pause()
            if !countdown.hasFinished { checkpoint() }
            countdown.stop()
        }
        .onChange(of: countdown.remainingSeconds) { _, seconds in
            // Periodic checkpoint in case iOS terminates the app unexpectedly.
            if seconds > 0 && seconds % 5 == 0 { checkpoint() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                countdown.pause()
                if !countdown.hasFinished { checkpoint() }
            }
        }
        .onChange(of: countdown.hasFinished) { _, finished in
            if finished { onFinished() }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func checkpoint() {
        store.saveFocus(
            examID: examID,
            stepID: stepID,
            remainingSeconds: countdown.remainingSeconds
        )
    }

    private func leaveAndSave() {
        countdown.pause()
        if !countdown.hasFinished { checkpoint() }
        onHome()
    }
}

