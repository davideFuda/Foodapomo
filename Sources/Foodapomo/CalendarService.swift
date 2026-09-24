import Foundation
import EventKit

@MainActor final class CalendarService: ObservableObject {
    let store = EKEventStore()
    @Published var events: [EKEvent] = []
    @Published var authorized = false

    func requestAccess() async {
        if #available(macOS 14.0, *) {
            authorized = (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            authorized = (try? await store.requestAccess(to: .event)) ?? false
        }
        loadEvents(for: Date())
    }

    func loadEvents(for date: Date) {
        guard authorized else { return }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        events = store.events(matching: store.predicateForEvents(withStart: start, end: end, calendars: nil)).sorted { $0.startDate < $1.startDate }
    }
}
