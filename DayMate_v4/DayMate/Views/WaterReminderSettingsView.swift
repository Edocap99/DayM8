import SwiftUI
import UIKit

struct WaterReminderSettingsView: View {
    @EnvironmentObject private var store: DayMateStore
    @Environment(\.dismiss) private var dismiss

    @State private var intervalHours = 2
    @State private var working = false
    @State private var showAlert = false
    @State private var permissionDenied = false
    @State private var alertText = ""

    private let service = WaterReminderService()

    var body: some View {
        ZStack {
            DayMateBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("Water reminders")
                            .font(.system(size: 28, weight: .bold))
                        Spacer()
                        Button("Done") { dismiss() }
                            .foregroundStyle(DayMateTheme.lilac)
                    }

                    DMCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("A gentle reminder to hydrate", systemImage: "drop.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(DayMateTheme.green)
                            Text("Choose how often DayMate reminds you to drink water. Notifications repeat daily between 9:00 AM and 9:00 PM.")
                                .font(.system(size: 14))
                                .foregroundStyle(DayMateTheme.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        DMSectionLabel(title: "Every")
                        Picker("Reminder interval", selection: $intervalHours) {
                            Text("1 h").tag(1)
                            Text("2 h").tag(2)
                            Text("3 h").tag(3)
                            Text("4 h").tag(4)
                        }
                        .pickerStyle(.segmented)
                        .tint(DayMateTheme.lilac)
                    }

                    DMCard {
                        HStack(spacing: 10) {
                            Image(systemName: store.waterReminderPreferences.enabled
                                  ? "bell.badge.fill" : "bell.slash")
                                .foregroundStyle(store.waterReminderPreferences.enabled
                                                 ? DayMateTheme.green : DayMateTheme.secondary)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(store.waterReminderPreferences.enabled
                                     ? "Reminders enabled" : "Reminders are off")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("\(scheduleDescription)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DayMateTheme.secondary)
                            }
                        }
                    }

                    DMButton(title: store.waterReminderPreferences.enabled
                             ? "Save reminder schedule" : "Enable reminders",
                             isEnabled: !working) {
                        Task { await update(enabled: true) }
                    }
                    if store.waterReminderPreferences.enabled {
                        Button("Turn off reminders") {
                            Task { await update(enabled: false) }
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DayMateTheme.secondary)
                        .frame(maxWidth: .infinity)
                        .disabled(working)
                    }
                    Text("iOS asks for notification permission when you enable reminders. You can disable them at any time. Reminders are time-based, even when you have already logged 8 glasses.")
                        .font(.system(size: 12))
                        .foregroundStyle(DayMateTheme.secondary)
                }
                .padding(22)
            }
        }
        .onAppear { intervalHours = store.waterReminderPreferences.intervalHours }
        .alert("Water reminders", isPresented: $showAlert) {
            if permissionDenied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertText)
        }
        .preferredColorScheme(.dark)
    }

    private var scheduleDescription: String {
        "Every \(intervalHours) hour\(intervalHours == 1 ? "" : "s") · 9 AM–9 PM"
    }

    @MainActor
    private func update(enabled: Bool) async {
        working = true
        defer { working = false }
        do {
            let granted = try await service.configure(enabled: enabled, intervalHours: intervalHours)
            if granted {
                store.setWaterReminderPreferences(
                    WaterReminderPreferences(enabled: enabled, intervalHours: intervalHours)
                )
            } else {
                permissionDenied = true
                alertText = "Notification access is disabled. Enable notifications for DayMate in iPhone Settings."
                showAlert = true
            }
        } catch {
            permissionDenied = false
            alertText = "Could not save reminders: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
