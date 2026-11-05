import SwiftUI

struct ExamDetailView: View {
    @EnvironmentObject private var store: DayMateStore

    let examID: UUID
    let onBack: () -> Void
    let onStart: () -> Void

    @State private var showDeleteConfirmation = false
    @State private var showAddChapter = false
    @State private var newChapterTitle = ""

    private var canSaveChapter: Bool {
        !newChapterTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            DayMateBackground()

            if let exam = store.exam(id: examID) {
                examContent(exam)
            } else {
                Text("Exam not found.")
                    .foregroundStyle(DayMateTheme.secondary)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddChapter) {
            addChapterSheet
        }
        .alert("Delete exam?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }

            Button("Delete permanently", role: .destructive) {
                store.deleteExam(id: examID)
                onBack()
            }
        } message: {
            Text("This exam and all its tiny steps will be permanently deleted.")
        }
    }

    // MARK: - Exam details

    private func examContent(_ exam: StudyExam) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 23) {
                    examHeader(exam)
                    progressCard(exam)
                    stepsCard(exam)
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 20)
            }

            DMButton(
                title: exam.nextStep == nil ? "All done!" : store.focusButtonTitle(for: examID),
                isEnabled: exam.nextStep != nil,
                action: onStart
            )
            .padding(.horizontal, 22)
            .padding(.bottom, 18)
        }
    }

    private func examHeader(_ exam: StudyExam) -> some View {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: exam.date)
        ).day ?? 0

        let dateDescription = exam.date.formatted(
            .dateTime.day().month(.wide)
        )
        let remainingText = days >= 0 ? "in \(days) days" : "date passed"

        return HStack(alignment: .top, spacing: 8) {
            DMHeader(
                backTitle: "Today",
                onBack: onBack,
                title: exam.subject,
                subtitle: "Exam on \(dateDescription) · \(remainingText)"
            )

            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(width: 44, height: 44)
                    .background(DayMateTheme.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete exam")
            .padding(.top, 27)
        }
    }

    private func progressCard(_ exam: StudyExam) -> some View {
        DMCard {
            HStack(spacing: 16) {
                DMProgressRing(
                    progress: exam.progress,
                    size: 64,
                    lineWidth: 7,
                    showText: true
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text("\(exam.completedCount) of \(exam.steps.count) steps done")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Keep it tiny, one at a time")
                        .font(.system(size: 12))
                        .foregroundStyle(DayMateTheme.secondary)
                }
            }
        }
    }

    private func stepsCard(_ exam: StudyExam) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            DMSectionLabel(title: "Tiny steps")

            DMCard(padding: 5) {
                VStack(spacing: 0) {
                    ForEach(exam.steps.indices, id: \.self) { index in
                        let step = exam.steps[index]

                        Button {
                            store.setStepCompleted(
                                examID: examID,
                                stepID: step.id,
                                completed: !step.isCompleted
                            )
                        } label: {
                            HStack(spacing: 15) {
                                DMStepCheck(isDone: step.isCompleted)

                                Text(step.title)
                                    .font(.system(
                                        size: 15,
                                        weight: .regular
                                    ))
                                    .foregroundStyle(
                                        step.isCompleted ? DayMateTheme.secondary : .white
                                    )

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 55)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index != exam.steps.count - 1 {
                            Divider()
                                .overlay(DayMateTheme.surfaceLight)
                                .padding(.leading, 55)
                        }
                    }

                    if !exam.steps.isEmpty {
                        Divider()
                            .overlay(DayMateTheme.surfaceLight)
                            .padding(.leading, 55)
                    }

                    Button {
                        newChapterTitle = ""
                        showAddChapter = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))

                            Text("Add a chapter")
                                .font(.system(size: 15, weight: .semibold))

                            Spacer()
                        }
                        .foregroundStyle(DayMateTheme.green)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 55)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Add chapter panel

    private var addChapterSheet: some View {
        NavigationStack {
            ZStack {
                DayMateBackground()

                VStack(alignment: .leading, spacing: 20) {
                    Text("Chapter name")
                        .font(.system(size: 16, weight: .semibold))

                    TextField("e.g. Chapter 4 - Functions", text: $newChapterTitle)
                        .dmInput()
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .onSubmit {
                            saveChapter()
                        }

                    Spacer(minLength: 0)

                    DMButton(
                        title: "Add chapter",
                        isEnabled: canSaveChapter
                    ) {
                        saveChapter()
                    }
                }
                .padding(22)
            }
            .navigationTitle("New chapter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showAddChapter = false
                    }
                    .tint(DayMateTheme.lilac)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    // MARK: - Actions

    private func saveChapter() {
        let title = newChapterTitle.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !title.isEmpty else { return }

        store.addChapter(examID: examID, title: title)
        newChapterTitle = ""
        showAddChapter = false
    }
}

