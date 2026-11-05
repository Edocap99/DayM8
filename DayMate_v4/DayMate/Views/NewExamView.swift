import SwiftUI

struct NewExamView: View {
    @EnvironmentObject private var store: DayMateStore
    let onCancel: () -> Void
    let onSaved: () -> Void

    @State private var subject = ""
    @State private var examDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var stepNames = ["", "", ""]

    private var valid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        stepNames.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        ZStack {
            DayMateBackground()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 23) {
                        DMHeader(backTitle: "Cancel", onBack: onCancel, title: "New exam")
                        VStack(alignment: .leading, spacing: 9) {
                            DMSectionLabel(title: "Subject")
                            TextField("e.g. Math", text: $subject).dmInput()
                                .textInputAutocapitalization(.words)
                        }
                        VStack(alignment: .leading, spacing: 9) {
                            DMSectionLabel(title: "Exam date")
                            DatePicker("Exam date", selection: $examDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .tint(DayMateTheme.lilac)
                                .padding(.horizontal, 14)
                                .frame(height: 53)
                                .background(DayMateTheme.surfaceLight, in: RoundedRectangle(cornerRadius: 15))
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            DMSectionLabel(title: "Tiny steps")
                            VStack(spacing: 3) {
                                ForEach(stepNames.indices, id: \.self) { index in
                                    HStack(spacing: 10) {
                                        Circle().stroke(DayMateTheme.secondary, lineWidth: 1.5)
                                            .frame(width: 22, height: 22)
                                        TextField("Step \(index + 1)", text: $stepNames[index])
                                            .font(.system(size: 15))
                                        if stepNames.count > 1 {
                                            Button {
                                                stepNames.remove(at: index)
                                            } label: {
                                                Image(systemName: "minus.circle")
                                                    .foregroundStyle(DayMateTheme.secondary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 15)
                                    .frame(height: 54)
                                    if index != stepNames.count - 1 {
                                        Divider().padding(.leading, 45)
                                    }
                                }
                                Button {
                                    stepNames.append("")
                                } label: {
                                    Label("Add a tiny step", systemImage: "plus")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(DayMateTheme.green)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 15)
                                        .frame(height: 52)
                                }
                                .buttonStyle(.plain)
                            }
                            .background(DayMateTheme.surface, in: RoundedRectangle(cornerRadius: 19))
                        }
                        DMCard {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Keep steps small!").font(.system(size: 14, weight: .semibold))
                                Text("10–25 minutes each works best")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DayMateTheme.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                }
                DMButton(title: "Save", isEnabled: valid) {
                    store.addExam(subject: subject, date: examDate, stepTitles: stepNames)
                    onSaved()
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 18)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
