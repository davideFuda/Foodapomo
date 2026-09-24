import SwiftUI
import SwiftData
import EventKit

struct CalendarView: View {
    @EnvironmentObject private var sessionStore: AppSessionStore
    @StateObject private var service = CalendarService()
    @State private var date = Date()
    @State private var selectedEventID: String?
    @State private var statusMessage: String?

    private var selectedEvent: EKEvent? { service.events.first { event in (event.eventIdentifier ?? event.title) == selectedEventID } }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 5) { Text("Calendario").font(.system(size: 34, weight: .bold)); Text("Scegli un evento e lavora su quello.").foregroundStyle(.secondary) }
                Spacer(); DatePicker("", selection: $date, displayedComponents: .date)
            }
            if !service.authorized {
                Spacer()
                ContentUnavailableView("Collega Apple Calendar", systemImage: "calendar.badge.plus", description: Text("Concedi l'accesso al calendario nelle Impostazioni di Sistema."))
                Button("Concedi accesso") { Task { await service.requestAccess(); service.loadEvents(for: date) } }.buttonStyle(.borderedProminent).tint(FoodapomoStyle.orange)
                Spacer()
            } else {
                if service.events.isEmpty { ContentUnavailableView("Nessun evento", systemImage: "calendar", description: Text("Non ci sono eventi per questa giornata.")) }
                else {
                    List(service.events, id: \.eventIdentifier, selection: $selectedEventID) { event in
                        let id = event.eventIdentifier ?? event.title
                        HStack(spacing: 14) {
                            Text(event.startDate, style: .time).font(.headline).frame(width: 65, alignment: .leading)
                            Circle().fill(FoodapomoStyle.orange).frame(width: 9, height: 9)
                            VStack(alignment: .leading) { Text(event.title).font(.headline); Text(event.location ?? "Evento calendario").font(.caption).foregroundStyle(.secondary) }
                            Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .contentShape(Rectangle())
                        .tag(id)
                    }
                    .scrollContentBackground(.hidden)
                }
                if let event = selectedEvent {
                    Button { useEvent(event) } label: { Label("Lavora su questo evento", systemImage: "play.fill").frame(maxWidth: .infinity) }
                        .buttonStyle(.borderedProminent).tint(FoodapomoStyle.orange).controlSize(.large)
                }
                if let statusMessage { Text(statusMessage).font(.caption).foregroundStyle(.green) }
            }
        }
        .padding(34)
        .onAppear { Task { await service.requestAccess(); service.loadEvents(for: date) } }
        .onChange(of: date) { _, value in selectedEventID = nil; service.loadEvents(for: value) }
    }

    private func useEvent(_ event: EKEvent) {
        let title = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
        sessionStore.selectedActivity = title
        sessionStore.selectedCalendarEventID = event.eventIdentifier
        sessionStore.selectedCalendarEventTitle = title
        statusMessage = "Evento selezionato. Apri Timer per iniziare la sessione."
    }
}

struct HistoryView: View {
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 22) { Text("Storico").font(.system(size: 34, weight: .bold)); Text("Il tuo percorso, un pomodoro alla volta.").foregroundStyle(.secondary); Text("Sessioni registrate: \(sessions.count)").font(.headline); ForEach(Array(sessions.prefix(30))) { session in HStack { Text(session.title).font(.headline); Spacer(); Text("\(session.actualSeconds / 60) min") }.padding().background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 16)) } }.padding(34) } }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var list: [PomodoroSettings]
    var body: some View { Group { if let settings = list.first { SettingsForm(settings: settings) } else { ProgressView().task { let settings = PomodoroSettings(); context.insert(settings); try? context.save() } } }.padding(34).navigationTitle("Impostazioni") }
}

private struct SettingsForm: View {
    @Bindable var settings: PomodoroSettings
    var body: some View { Form { Section("Sessioni") { Stepper("Durata: \(settings.focusMinutes) minuti", value: $settings.focusMinutes, in: 1...180); Stepper("Obiettivo giornaliero: \(settings.dailyGoal)", value: $settings.dailyGoal, in: 1...24) }; Section("Pause") { Stepper("Pausa breve: \(settings.shortBreakMinutes) minuti", value: $settings.shortBreakMinutes, in: 1...60); Stepper("Pausa lunga: \(settings.longBreakMinutes) minuti", value: $settings.longBreakMinutes, in: 1...120); Stepper("Pausa lunga ogni \(settings.sessionsBeforeLongBreak) sessioni", value: $settings.sessionsBeforeLongBreak, in: 1...12) }; Toggle("Avvia automaticamente la pausa", isOn: $settings.autoStartBreak) }.formStyle(.grouped) }
}
