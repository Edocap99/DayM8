import SwiftUI

struct DMSectionBar: View {

    enum Section {
        case study, plan
    }

    let selection: Section
    let onStudy: () -> Void
    let onPlan: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            sectionButton(
                .study,
                title: "Study",
                symbol: "book.closed.fill",
                action: onStudy
            )

            sectionButton(
                .plan,
                title: "Plan my day",
                symbol: "calendar",
                action: onPlan
            )
        }
        .padding(7)
        .background(
            DayMateTheme.surface,
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    DayMateTheme.lilac.opacity(0.20),
                    lineWidth: 1
                )
        }
        .padding(.horizontal, 22)
        .padding(.top, 7)
        .padding(.bottom, 8)
        .background(
            DayMateTheme.background.opacity(0.97)
        )
    }

    private func sectionButton(
        _ section: Section,
        title: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {

        let isSelected = selection == section

        return Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(
                    size: 14,
                    weight: .semibold
                ))
                .foregroundStyle(
                    isSelected
                    ? DayMateTheme.background
                    : DayMateTheme.secondary
                )
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSelected
                            ? AnyShapeStyle(DayMateTheme.gradient)
                            : AnyShapeStyle(Color.clear)
                        )
                }
        }
        .buttonStyle(.plain)
    }
}
