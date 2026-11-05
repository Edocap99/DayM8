import SwiftUI

struct WelcomeBackView: View {
    let onToday: () -> Void
    let onPlan: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            DayMateBackground()
            VStack(spacing: 20) {
                Spacer()
                MascotView()
                Text("Welcome back!")
                    .font(.system(size: 30, weight: .bold))
                Text("Every tiny step counts. Ready for the next one?")
                    .font(.system(size: 15))
                    .foregroundStyle(DayMateTheme.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
                VStack(spacing: 12) {
                    DMButton(title: "Continue studying", action: onToday)
                    DMButton(title: "Plan my day", action: onPlan)
                    Button("Close", action: onClose)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DayMateTheme.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        .accessibilityHint("Return to the DayMate home screen")
                }
                Spacer(minLength: 24)
            }
            .padding(.horizontal, 22)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
}
#Preview{
}
