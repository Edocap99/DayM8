import SwiftUI

struct HomeView: View {
    let onStudy: () -> Void
    let onPlan: () -> Void
    let transitionNamespace: Namespace.ID

    @State private var launching: HomeEntry?

    var body: some View {
        ZStack {
            DayMateBackground()
            VStack(spacing: 0) {
                Spacer(minLength: 20)
                MascotView()
                Text("DayMate")
                    .font(.system(size: 37, weight: .bold, design: .rounded))
                    .foregroundStyle(DayMateTheme.gradient)
                    .padding(.top, 6)
                Text("One tiny step at a time")
                    .font(.system(size: 16))
                    .foregroundStyle(DayMateTheme.secondary)
                    .padding(.top, 4)
                Spacer(minLength: 50)
                VStack(spacing: 12) {
                    homeButton(.study)
                        .modifier(DMHomeZoomSource(id: HomeEntry.study.rawValue,
                                                   namespace: transitionNamespace))
                    homeButton(.plan)
                        .modifier(DMHomeZoomSource(id: HomeEntry.plan.rawValue,
                                                   namespace: transitionNamespace))
                }
                .padding(.horizontal, 24)
                Spacer(minLength: 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func homeButton(_ entry: HomeEntry) -> some View {
        let highlighted = launching == entry
        Button { open(entry) } label: {
            HStack(spacing: 14) {
                Image(systemName: entry == .study ? "book.closed.fill" : "calendar")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(highlighted ? DayMateTheme.lilac : .white)
                    .frame(width: 40, height: 40)
                    .background(highlighted ? DayMateTheme.background : DayMateTheme.surfaceLight,
                                in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry == .study ? "Study" : "Plan my day")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text(entry == .study ? "Start a tiny step " : "Organize your day") .font(.system(size:12))
                    
                }
                Spacer()
                if launching == entry {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 17, weight: .bold))
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .foregroundStyle(highlighted ? DayMateTheme.background : .white)
            .padding(.horizontal, 16)
            .frame(height: 66)
            .background {
                RoundedRectangle(cornerRadius: 19)
                    .fill(highlighted ? AnyShapeStyle(DayMateTheme.gradient)
                         : AnyShapeStyle(DayMateTheme.surface))
            }
            .scaleEffect(launching == entry ? 1.035 : 1)
            .shadow(color: highlighted && launching == entry ? DayMateTheme.purple.opacity(0.35) : .clear,
                    radius: 18, y: 3)
            .contentShape(RoundedRectangle(cornerRadius: 19))
        }
        .buttonStyle(DMHomePressStyle())
        .disabled(launching != nil)
        .accessibilityLabel(entry == .study ? "Study" : "Plan my day")
    }

    private func open(_ entry: HomeEntry) {
        guard launching == nil else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
            launching = entry
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            switch entry {
            case .study: onStudy()
            case .plan: onPlan()
            }
            try? await Task.sleep(for: .milliseconds(380))
            launching = nil
        }
    }
}
