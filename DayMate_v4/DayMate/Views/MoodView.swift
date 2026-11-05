import SwiftUI

struct MoodView: View {
    let onCancel: () -> Void
    let onSave: (Mood) -> Void

    @State private var selected: Mood = .ready

    var body: some View {
        ZStack {
            DayMateBackground()

            VStack(alignment: .leading, spacing: 22) {
                DMHeader(
                    backTitle: "Cancel",
                    onBack: onCancel,
                    title: "How do you feel?",
                    subtitle: "Your next step adapts to you"
                )

                DMCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Mood.allCases) { mood in
                            moodRow(for: mood)

                            if mood != Mood.allCases.last {
                                Divider()
                                    .overlay(DayMateTheme.surfaceLight)
                                    .padding(.leading, 96)
                            }
                        }
                    }
                }
                .padding(.top, 5)

                DMButton(title: "Save") {
                    onSave(selected)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // Each row keeps the illustration on the left, text in the center,
    // and the selection indicator on the right.
    private func moodRow(for mood: Mood) -> some View {
        let isSelected = selected == mood

        return Button {
            selected = mood
        } label: {
            HStack(spacing: 12) {
                Image(mood.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(mood.rawValue)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(mood.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(DayMateTheme.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .font(.system(size: isSelected ? 22 : 17, weight: .semibold))
                    .foregroundStyle(isSelected ? DayMateTheme.green : DayMateTheme.secondary)
                    .frame(width: 26)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 92)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
