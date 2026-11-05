import SwiftUI

@main
struct DayMateApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = DayMateStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .task {
                    await store.reconcileActivityReminders()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await store.reconcileActivityReminders() }
                    }
                }
        }
    }
}

