import SwiftUI

enum DayMateRoute: Hashable {
    case workspace
    case examDetail(UUID)
    case newExam
    case mood(UUID)
    case focus(UUID)
    case breakChoice
    case breakTimer(BreakActivity)
    case welcomeBack
}

struct RootView: View {
    @EnvironmentObject private var store: DayMateStore
    @State private var path: [DayMateRoute] = []
    @State private var section: DMSectionBar.Section = .study
    @Namespace private var homeTransition

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                onStudy: { openWorkspace(.study) },
                onPlan: { openWorkspace(.plan) },
                transitionNamespace: homeTransition
            )
            .navigationDestination(for: DayMateRoute.self) { route in
                destination(for: route)
            }
        }
        .tint(DayMateTheme.lilac)
    }

    @ViewBuilder
    private func destination(for route: DayMateRoute) -> some View {
        switch route {
        case .workspace:
            DayMateMainSectionsView(
                selection: $section,
                onHome: { path = [] },
                onAddExam: { path.append(.newExam) },
                onExam: { path.append(.examDetail($0)) },
                onQuickStart: { openFocusOrMood(examID: $0) }
            )
            .modifier(
                DMHomeZoomDestination(
                    id: section == .study
                        ? HomeEntry.study.rawValue
                        : HomeEntry.plan.rawValue,
                    namespace: homeTransition
                )
            )
            // Niente DMGradientArrival: lo sfondo non deve schiarirsi.

        case .examDetail(let id):
            ExamDetailView(
                examID: id,
                onBack: { pop() },
                onStart: { openFocusOrMood(examID: id) }
            )

        case .newExam:
            NewExamView(onCancel: { pop() }, onSaved: { pop() })

        case .mood(let id):
            MoodView(onCancel: { pop() }, onSave: { mood in
                store.saveMood(mood)
                if mood == .stressed {
                    path.append(.breakChoice)
                } else {
                    store.beginFocus(examID: id, minutes: mood.durationMinutes)
                    path.append(.focus(id))
                }
            })

        case .focus(let examID):
            if let session = store.focusSession(for: examID) {
                FocusTimerView(
                    examID: examID,
                    stepID: session.stepID,
                    totalSeconds: session.totalSeconds,
                    remainingSeconds: session.remainingSeconds,
                    onHome: { returnToWorkspace(.study) },
                    onFinished: {
                        store.completeFocus(examID: examID, stepID: session.stepID)
                        path.append(.breakChoice)
                    }
                )
            } else {
                // No ongoing focus session: return to Study instead of showing a broken timer.
                TodayView(
                    onHome: { path = [] },
                    onAddExam: { path.append(.newExam) },
                    onExam: { path.append(.examDetail($0)) },
                    onQuickStart: { openFocusOrMood(examID: $0) }
                )
            }

        case .breakChoice:
            BreakChoiceView(
                onHome: { returnToWorkspace(.study) },
                onStart: { path.append(.breakTimer($0)) }
            )

        case .breakTimer(let activity):
            BreakTimerView(
                activity: activity,
                onFinished: { path.append(.welcomeBack) }
            )

        case .welcomeBack:
            WelcomeBackView(
                onToday: { returnToWorkspace(.study) },
                onPlan: { returnToWorkspace(.plan) },
                onClose: { path = [] }
            )
        }
    }

    /// Resume an unfinished session, otherwise ask for the user's mood.
    private func openFocusOrMood(examID: UUID) {
        guard store.selection(for: examID) != nil else { return }
        if store.focusSession(for: examID) != nil {
            navigate(to: .focus(examID))
        } else {
            navigate(to: .mood(examID))
        }
    }

    private func openWorkspace(_ newSection: DMSectionBar.Section) {
        section = newSection
        navigate(to: .workspace)
    }

    private func returnToWorkspace(_ newSection: DMSectionBar.Section) {
        section = newSection
        path = [.workspace]
    }

    private func navigate(to route: DayMateRoute) {
        withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
            path.append(route)
        }
    }

    private func pop() {
        if !path.isEmpty { path.removeLast() }
    }
}

// Una sola destinazione nello stack. Il cambio di sezione non fa push/pop.
private struct DayMateMainSectionsView: View {
    @Binding var selection: DMSectionBar.Section
    let onHome: () -> Void
    let onAddExam: () -> Void
    let onExam: (UUID) -> Void
    let onQuickStart: (UUID) -> Void

    var body: some View {
        ZStack {
            DayMateBackground()

            // Le due View restano montate: il calendario mantiene il suo stato.
            TodayView(
                onHome: onHome,
                onAddExam: onAddExam,
                onExam: onExam,
                onQuickStart: onQuickStart
            )
            .opacity(selection == .study ? 1 : 0)
            .offset(x: selection == .study ? 0 : -22)
            .allowsHitTesting(selection == .study)
            .accessibilityHidden(selection != .study)

            PlanView(onBack: onHome)
                .opacity(selection == .plan ? 1 : 0)
                .offset(x: selection == .plan ? 0 : 22)
                .allowsHitTesting(selection == .plan)
                .accessibilityHidden(selection != .plan)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DMSectionBar(
                selection: selection,
                onStudy: { changeSection(to: .study) },
                onPlan: { changeSection(to: .plan) }
            )
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func changeSection(to newSection: DMSectionBar.Section) {
        guard selection != newSection else { return }

        withAnimation(.spring(response: 0.34, dampingFraction: 0.90)) {
            selection = newSection
        }
    }
}

