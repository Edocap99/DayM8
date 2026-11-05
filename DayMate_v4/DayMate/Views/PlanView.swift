import SwiftUI


struct PlanView: View {
    @EnvironmentObject private var store: DayMateStore
    let onBack: () -> Void

    @StateObject private var calendar = PlannerCalendarViewModel()
    @State private var showDatePicker = false
    @State private var showWaterReminders = false
    @State private var activitySheet: DayMateActivitySheet?
    @State private var taskPendingDeletion: DayTask?

    private var tasks: [DayTask] {
        store.tasks(for: calendar.selectedDay)
    }

    var body: some View {
        ZStack {
            DayMateBackground()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        planHeader

                        WeekCalendarView(
                            calendar: calendar,
                            onChooseDate: { showDatePicker = true }
                        )

                        taskSection(
                            "Study",
                            items: tasks.filter { $0.kind == .study }
                        )

                        taskSection(
                            "Duties & free time",
                            items: tasks.filter { $0.kind != .study }
                        )

                        waterSection
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 25)
                }

            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activitySheet) { sheet in
            NewPlanItemView(
                day: sheet.day,
                onCancel: { activitySheet = nil },
                onSaved: { activitySheet = nil }
            )
            .environmentObject(store)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showWaterReminders) {
            WaterReminderSettingsView()
                .environmentObject(store)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDatePicker) {
            VStack(spacing: 16) {
                DatePicker(
                    "Choose a date",
                    selection: Binding(
                        get: { calendar.selectedDay },
                        set: { calendar.select($0) }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(DayMateTheme.lilac)
                .padding(.horizontal, 12)

                DMButton(title: "Done") {
                    showDatePicker = false
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 0)
            }
            .padding(.top, 20)
            .background(DayMateTheme.background)
            .presentationDetents([.medium, .large])
        }
        .alert(item: $taskPendingDeletion) { task in
            Alert(
                title: Text("Delete activity?"),
                message: Text(
                    "\(task.title) will be permanently removed from your planner."
                ),
                primaryButton: .destructive(Text("Delete")) {
                    store.deleteTask(id: task.id)
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }

    // MARK: - Header

    private var planHeader: some View {
        HStack(alignment: .bottom, spacing: 12) {
            DMHeader(
                backTitle: "Home",
                onBack: onBack,
                title: "Plan"
            )

            Button {
                openNewActivity()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(DayMateTheme.green)
                    .frame(width: 40, height: 40)
                    .background(DayMateTheme.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add activity")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Tasks

    private func openNewActivity() {
        activitySheet = DayMateActivitySheet(day: calendar.selectedDay)
    }

    private func taskSection(_ name: String, items: [DayTask]) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            DMSectionLabel(title: name)

            if items.isEmpty {
                Text("No activities planned.")
                    .font(.system(size: 13))
                    .foregroundStyle(DayMateTheme.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            } else {
                DMCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(items) { item in
                            HStack(spacing: 0) {
                                Button {
                                    store.toggleTask(id: item.id)
                                } label: {
                                    HStack(spacing: 13) {
                                        DMStepCheck(isDone: item.isCompleted)

                                        Text(item.title)
                                            .font(.system(
                                                size: 14,
                                                weight: item.isCompleted ? .regular : .medium
                                            ))
                                            .foregroundStyle(
                                                item.isCompleted
                                                    ? DayMateTheme.secondary : .white
                                            )

                                        Spacer(minLength: 4)

                                        Text(item.scheduledAt.formatted(
                                            .dateTime.hour().minute()
                                        ))
                                        .font(.system(size: 12))
                                        .foregroundStyle(DayMateTheme.secondary)
                                    }
                                    .padding(.leading, 14)
                                    .frame(minHeight: 54)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(
                                    "\(item.isCompleted ? "Uncomplete" : "Complete") \(item.title)"
                                )

                                Button {
                                    taskPendingDeletion = item
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(DayMateTheme.secondary)
                                        .frame(width: 44, height: 54)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Delete \(item.title)")
                                .padding(.trailing, 6)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Water (always visible, even on other dates)

    private var waterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                DMSectionLabel(title: "Water")
                Spacer()

                Button {
                    showWaterReminders = true
                } label: {
                    Label(
                        "Reminders",
                        systemImage: store.waterReminderPreferences.enabled
                            ? "bell.badge.fill" : "bell"
                    )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DayMateTheme.lilac)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Configure water reminders")
            }

            DMCard {
                HStack(spacing: 5) {
                    ForEach(1...8, id: \.self) { index in
                        Button {
                            store.setWaterCount(
                                index == store.todayWaterCount ? index - 1 : index
                            )
                        } label: {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 21))
                                .foregroundStyle(
                                    index <= store.todayWaterCount
                                        ? DayMateTheme.green
                                        : DayMateTheme.surfaceLight
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Set water count to \(index)")
                    }

                    Spacer(minLength: 3)

                    Text("\(store.todayWaterCount)/8")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DayMateTheme.secondary)
                }
            }
        }
    }
}

// Opening the sheet again creates a fresh activity form; swipe-down dismisses it.
private struct DayMateActivitySheet: Identifiable {
    let id = UUID()
    let day: Date
}
