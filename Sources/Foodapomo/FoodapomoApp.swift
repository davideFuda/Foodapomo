import SwiftUI
import SwiftData

@MainActor final class AppSessionStore: ObservableObject {
    @Published var selectedActivity = ""
    @Published var selectedCalendarEventID: String?
    @Published var selectedCalendarEventTitle: String?
}

@main
struct FoodapomoApp: App {
    @StateObject private var sessionStore = AppSessionStore()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([FocusSession.self, PomodoroSettings.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [configuration]) }
        catch { fatalError("Unable to create model container: \(error)") }
    }()

    var body: some Scene {
        WindowGroup { RootView().environmentObject(sessionStore) }
            .modelContainer(sharedModelContainer)
        MenuBarExtra("Foodapomo", systemImage: "timer") {
            MenuBarView().environmentObject(sessionStore).modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)
    }
}
