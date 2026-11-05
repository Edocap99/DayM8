import SwiftUI

/// Original mascot supplied by the design team. Its transparent padding is
/// normalized in Assets so the mascot stays visually centered on every iPhone.
struct MascotView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(DayMateTheme.purple.opacity(0.44), lineWidth: 1)
                .frame(width: 294, height: 294)
            Circle()
                .stroke(DayMateTheme.green.opacity(0.50), lineWidth: 1)
                .frame(width: 235, height: 235)
            Circle()
                .fill(DayMateTheme.purple.opacity(0.10))
                .frame(width: 184, height: 184)

            Image("DayMateMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 242, height: 282)
                .offset(y: -20) // Centers the body inside the concentric rings.
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 322)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("DayMate purple smiling mascot")
    }
}
