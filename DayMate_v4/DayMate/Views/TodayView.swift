import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: DayMateStore
    let onHome: () -> Void
    let onAddExam: () -> Void
    let onExam: (UUID) -> Void
    let onQuickStart: (UUID) -> Void
    @State private var examPendingDeletion: StudyExam?

    var body: some View {
        ZStack {
            DayMateBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    DMHeader(onBack: onHome, title: "Study",
                             subtitle: Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    if let selection = store.nextSelection {
                        DMCard {
                            VStack(alignment: .leading, spacing: 7) {
                                Text("NEXT TINY STEP")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(DayMateTheme.green)
                                Text(selection.step.title)
                                    .font(.system(size: 25, weight: .bold))
                                Text("\(selection.exam.subject) · step \(selection.stepIndex + 1) of \(selection.exam.steps.count)")
                                    .font(.system(size: 14))
                                    .foregroundStyle(DayMateTheme.secondary)
                                Button(action: { onQuickStart(selection.exam.id) }) {
                                    Label(store.focusButtonTitle(for: selection.exam.id), systemImage: "play.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(DayMateTheme.background)
                                        .padding(.horizontal, 18)
                                        .frame(height: 36)
                                        .background(DayMateTheme.gradient, in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 12)
                            }
                        }
                    } else {
                        DMCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("You're all caught up!").font(.headline)
                                Text("Add an exam to create your next tiny step.")
                                    .foregroundStyle(DayMateTheme.secondary)
                            }
                        }
                    }
                    Button(action: onAddExam) {
                        HStack {
                            Text("Add an exam").font(.system(size: 20, weight: .bold))
                            Spacer()
                            Image(systemName: "plus.circle.fill").font(.system(size: 27))
                        }
                        .foregroundStyle(DayMateTheme.background)
                        .padding(.horizontal, 16)
                        .frame(height: 60)
                        .background(DayMateTheme.gradient, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 12) {
                        DMSectionLabel(title: "Your exams")
                        if store.sortedExams.isEmpty {
                            Text("No exams added yet.")
                                .foregroundStyle(DayMateTheme.secondary)
                        }
                        ForEach(store.sortedExams) { exam in
                            HStack(spacing: 7) {
                                Button { onExam(exam.id) } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "book.closed.fill")
                                            .font(.system(size: 19))
                                            .foregroundStyle(DayMateTheme.lilac)
                                            .frame(width: 40, height: 40)
                                            .background(DayMateTheme.surfaceLight,
                                                        in: RoundedRectangle(cornerRadius: 12))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(exam.subject)
                                                .font(.system(size: 16, weight: .semibold))
                                                .lineLimit(1)
                                            Text("\(exam.date.formatted(.dateTime.day().month(.abbreviated))) · \(exam.completedCount) of \(exam.steps.count) steps")
                                                .font(.system(size: 12))
                                                .foregroundStyle(DayMateTheme.secondary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                        Spacer(minLength: 3)
                                        DMProgressRing(progress: exam.progress, size: 29, lineWidth: 4)
                                    }
                                    .foregroundStyle(.white)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                // This is a separate control, not a Button nested inside a Button.
                                Button {
                                    examPendingDeletion = exam
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(DayMateTheme.secondary)
                                        .frame(width: 40, height: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Delete \(exam.subject)")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 13)
                            .background(DayMateTheme.surface,
                                        in: RoundedRectangle(cornerRadius: 17))
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 50)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        // Using the Identifiable exam as the alert item captures the correct
        // exam even if SwiftUI clears the alert state before its button action.
        .alert(item: $examPendingDeletion) { exam in
            Alert(
                title: Text("Delete \(exam.subject)?"),
                message: Text("This exam and its tiny steps will be deleted permanently. This cannot be undone."),
                primaryButton: .destructive(Text("Delete permanently")) {
                    store.deleteExam(id: exam.id)
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
}

