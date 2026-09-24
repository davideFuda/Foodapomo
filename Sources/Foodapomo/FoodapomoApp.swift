import SwiftUI
import SwiftData

@main
struct FoodapomoApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([FocusSession.self, PomodoroSettings.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [configuration]) }
        catch { fatalError("Unable to create model container: \(error)") }
    }()

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(sharedModelContainer)
        MenuBarExtra("Foodapomo", systemImage: "timer") {
            MenuBarView().modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)
    }
}
