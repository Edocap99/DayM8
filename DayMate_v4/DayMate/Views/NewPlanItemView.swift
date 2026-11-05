import SwiftUI
import UIKit

struct NewPlanItemView: View {
    @EnvironmentObject private var store: DayMateStore
    let day: Date
    let onCancel: () -> Void
    let onSaved: () -> Void

    @State private var title = ""
    @State private var kind: TaskKind = .study
    @State private var chosenTime: Date
    @State private var duration: Int = 30

    // New activities offer a notification by default. Nothing is scheduled
    // until the user presses Add and iOS has granted notification permission.
    @State private var remindAtStart = true
    @State private var saving = false
    @State private var showNotice = false
    @State private var noticeText = ""
    @State private var permissionDenied = false

    private let reminders = ActivityReminderService()

    init(day: Date, onCancel: @escaping () -> Void, onSaved: @escaping () -> Void) {
        self.day = day
        self.onCancel = onCancel
        self.onSaved = onSaved
        _chosenTime = State(initialValue: Calendar.current.date(
            bySettingHour: 15,
            minute: 0,
            second: 0,
            of: day
        ) ?? day)
    }

    private var valid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Keep the day chosen in Plan and the time chosen in the sheet.
    /// This prevents a time-only DatePicker from accidentally changing the day.
    private var scheduledAt: Date {
        let components = Calendar.current.dateComponents([.hour, .minute], from: chosenTime)
        return Calendar.current.date(
            bySettingHour: components.hour ?? 15,
            minute: components.minute ?? 0,
            second: 0,
            of: day
        ) ?? chosenTime
    }

    private var reminderIsInFuture: Bool {
        scheduledAt > Date().addingTimeInterval(5)
    }

    var body: some View {
        ZStack {
            DayMateBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Add to your day")
                        .font(.system(size: 27, weight: .bold))

                    TextField("e.g. Gym, lab report...", text: $title)
                        .dmInput()

                    VStack(alignment: .leading, spacing: 10) {
                        DMSectionLabel(title: "Type")

                        HStack(spacing: 9) {
                            ForEach(TaskKind.allCases) { option in
                                Button { kind = option } label: {
                                    VStack(spacing: 10) {
                                        Image(systemName: option.symbol)
                                            .font(.system(size: 19))
                                        Text(option.rawValue)
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundStyle(
                                        kind == option ? DayMateTheme.background : .white
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 94)
                                    .background(
                                        kind == option ? DayMateTheme.purple : DayMateTheme.surface,
                                        in: RoundedRectangle(cornerRadius: 17)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        DMSectionLabel(title: "When")

                        DMCard {
                            VStack(spacing: 14) {
                                HStack {
                                    Text("Date")
                                    Spacer()
                                    Text(day.formatted(.dateTime.day().month(.wide).year()))
                                        .foregroundStyle(DayMateTheme.secondary)
                                        .font(.system(size: 14))
                                }

                                Divider()

                                HStack {
                                    Text("Time")
                                    Spacer()
                                    DatePicker(
                                        "Time",
                                        selection: $chosenTime,
                                        displayedComponents: .hourAndMinute
                                    )
                                    .labelsHidden()
                                    .tint(DayMateTheme.lilac)
                                }

                                Divider()

                                HStack {
                                    Text("Duration")
                                    Spacer()
                                    Picker("Duration", selection: $duration) {
                                        ForEach([5, 10, 15, 25, 30, 45, 60, 90, 120], id: \.self) { value in
                                            Text("\(value) min").tag(value)
                                        }
                                    }
                                    .tint(DayMateTheme.lilac)
                                }
                            }
                        }
                    }

                    DMCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $remindAtStart) {
                                Label("Remind me at start time", systemImage: "bell")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .tint(DayMateTheme.green)

                            Text(reminderIsInFuture
                                 ? "A one-time notification at the selected date and time."
                                 : "The selected time is in the past. No notification will be scheduled.")
                                .font(.system(size: 12))
                                .foregroundStyle(DayMateTheme.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Button {
                        Task {
                            await saveActivity()
                        }
                    } label: {
                        Text(saving ? "Saving..." : "Add")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(
                                valid && !saving
                                    ? DayMateTheme.background
                                    : Color.white
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background {
                                Capsule()
                                    .fill(
                                        valid && !saving
                                            ? AnyShapeStyle(DayMateTheme.gradient)
                                            : AnyShapeStyle(DayMateTheme.surfaceLight)
                                    )
                            }
                            .overlay {
                                Capsule()
                                    .strokeBorder(
                                        DayMateTheme.lilac.opacity(0.45),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(!valid || saving)

                    Button("Cancel", action: onCancel)
                        .foregroundStyle(DayMateTheme.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .disabled(saving)

                    Spacer(minLength: 18)
                }
                .padding(.horizontal, 22)
                .padding(.top, 38)
                .padding(.bottom, 36)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Activity saved", isPresented: $showNotice) {
            if permissionDenied {
                Button("Open Settings") {
                    onSaved()
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            Button("OK", role: .cancel) {
                onSaved()
            }
        } message: {
            Text(noticeText)
        }
    }

    @MainActor
    private func saveActivity() async {
        guard valid, !saving else { return }
        saving = true
        defer { saving = false }

        // For past times or when the switch is off, save normally without an alert.
        let needsReminder = remindAtStart && reminderIsInFuture
        var authorized = false
        var notificationWarning: String?
        permissionDenied = false

        if needsReminder {
            do {
                authorized = try await reminders.requestPermission()
                if !authorized {
                    permissionDenied = true
                    notificationWarning = "Your activity was saved. Allow DayMate notifications in iPhone Settings, then reopen the app before the activity time to enable this reminder."
                }
            } catch {
                notificationWarning = "Your activity was saved, but notification permission could not be checked: \(error.localizedDescription)"
            }
        } else if remindAtStart && !reminderIsInFuture {
            notificationWarning = "Your activity was saved. Its date or time is in the past, so no notification was scheduled."
        }

        guard let task = store.addTask(
            title: title,
            kind: kind,
            at: scheduledAt,
            duration: duration,
            // Keep the user's choice even if permission is currently denied.
            // The app will retry when iOS permission becomes available.
            remindAtStart: needsReminder
        ) else { return }

        if authorized {
            do {
                try await reminders.schedule(task)
            } catch {
                notificationWarning = "Your activity was saved, but the reminder could not be scheduled yet: \(error.localizedDescription). DayMate will retry when you reopen the app."
            }
        }

        if let notificationWarning {
            noticeText = notificationWarning
            showNotice = true
        } else {
            onSaved()
        }
    }
}

