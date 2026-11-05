import SwiftUI

struct BreakTimerView: View {
    let activity: BreakActivity
    let onFinished: () -> Void
    @StateObject private var countdown: CountdownViewModel

    init(activity: BreakActivity, onFinished: @escaping () -> Void) {
        self.activity = activity
        self.onFinished = onFinished
        _countdown = StateObject(wrappedValue: CountdownViewModel(minutes: activity.minutes))
    }

    var body: some View {
        ZStack {
            DayMateBackground()
            VStack(spacing: 19) {
                Spacer()
                Text("Take it slow")
                    .font(.system(size: 32, weight: .bold))
                Text(activity.rawValue)
                    .foregroundStyle(DayMateTheme.secondary)
                ZStack {
                    Circle().stroke(DayMateTheme.purple.opacity(0.36), lineWidth: 1)
                        .frame(width: 298, height: 298)
                    Circle().stroke(DayMateTheme.green.opacity(0.48), lineWidth: 1)
                        .frame(width: 250, height: 250)
                    Circle().stroke(DayMateTheme.surfaceLight, lineWidth: 13)
                        .frame(width: 204, height: 204)
                    Circle().trim(from: 0, to: countdown.progress)
                        .stroke(DayMateTheme.green,
                                style: StrokeStyle(lineWidth: 13, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 204, height: 204)
                    Text(countdown.clockText)
                        .font(.system(size: 43, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .frame(height: 340)
                Text("Give yourself time away from the screen.")
                    .font(.system(size: 14))
                    .foregroundStyle(DayMateTheme.secondary)
                HStack(spacing: 14) {
                    Button { countdown.toggle() } label: {
                        Label(countdown.isRunning ? "Pause" : "Resume",
                              systemImage: countdown.isRunning ? "pause.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(DayMateTheme.surfaceLight, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    DMButton(title: "I'm ready") { countdown.finish() }
                }
                Spacer()
            }
            .padding(.horizontal, 23)
        }
        .onAppear { countdown.start() }
        .onDisappear { countdown.stop() }
        .onChange(of: countdown.hasFinished) { _, finished in
            if finished { onFinished() }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
