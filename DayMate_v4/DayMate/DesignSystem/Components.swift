import SwiftUI

struct DMButton: View {
    let title: String
    var symbol: String? = nil
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let symbol { Image(systemName: symbol) }
                Text(title).font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(DayMateTheme.background)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(DayMateTheme.gradient, in: Capsule())
            .opacity(isEnabled ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct DMCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DayMateTheme.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

struct DMHeader: View {
    var backTitle: String = "Home"
    var onBack: () -> Void
    var title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onBack) {
                Label(backTitle, systemImage: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DayMateTheme.secondary)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)
            Text(title).font(.system(size: 30, weight: .bold))
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(DayMateTheme.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DMProgressRing: View {
    let progress: Double
    var size: CGFloat = 54
    var lineWidth: CGFloat = 7
    var showText: Bool = false

    var body: some View {
        ZStack {
            Circle().stroke(DayMateTheme.surfaceLight, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(DayMateTheme.green,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if showText {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .semibold))
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Progress \(Int(progress * 100)) percent")
    }
}

struct DMSectionLabel: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(DayMateTheme.secondary)
    }
}

struct DMStepCheck: View {
    let isDone: Bool
    var active: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(isDone || active ? DayMateTheme.green : DayMateTheme.secondary,
                        lineWidth: 1.8)
                .frame(width: 23, height: 23)
            if isDone {
                Circle().fill(DayMateTheme.green).frame(width: 23, height: 23)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DayMateTheme.background)
            } else if active {
                Circle().fill(DayMateTheme.green).frame(width: 9, height: 9)
            }
        }
    }
}

struct DMInput: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .frame(height: 51)
            .background(DayMateTheme.surfaceLight, in: RoundedRectangle(cornerRadius: 15))
    }
}

extension View {
    func dmInput() -> some View { modifier(DMInput()) }
}
