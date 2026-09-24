import SwiftUI
import SwiftData
import EventKit

struct CalendarView: View {
    @StateObject private var service = CalendarService()
    @State private var date = Date()
    @State private var selected: EKEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Calendario").font(.largeTitle.bold())
                    Text("Scegli un evento e inizia a lavorare su quello.").foregroundStyle(.secondary)
                }
                Spacer()
                DatePicker("", selection: $date, displayedComponents: .date)
                    .onChange(of: date) { _, value in
                        service.loadEvents(for: value)
                    }
            }
            .padding(.bottom, 12)

            if !service.authorized {
                ContentUnavailableView(
                    "Collega Apple Calendar",
                    systemImage: "calendar.badge.plus",
                    description: Text("Concedi l'accesso per vedere i tuoi eventi.")
                )
                Button("Concedi accesso") {
                    Task { await service.requestAccess() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            } else {
                List(service.events, id: \.eventIdentifier, selection: $selected) { event in
                    HStack {
                        Text(event.startDate, style: .time).frame(width: 70, alignment: .leading)
                        VStack(alignment: .leading) {
                            Text(event.title)
                            if let location = event.location {
                                Text(location).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                    }
                    .padding(8)
                }
                .frame(maxHeight: .infinity)

                Button("Inizia sessione su questo evento") {
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(selected == nil)
            }
        }
        .padding(32)
        .onAppear {
            Task { await service.requestAccess() }
        }
    }
}

struct HistoryView: View {
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Storico").font(.largeTitle.bold())
                Text("Il tuo percorso, un pomodoro alla volta.").foregroundStyle(.secondary)

                summary
                hourly

                Text("Sessioni recenti").font(.title2.bold())

                ForEach(Array(sessions.prefix(20))) { session in
                    HStack {
                        Image(systemName: session.status == SessionStatus.completed ? "checkmark.circle.fill" : "pause.circle")
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading) {
                            Text(session.title).font(.headline)
                            Text("\(session.startedAt.formatted(date: .abbreviated, time: .shortened)) – \(session.endedAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(session.actualSeconds / 60) min").font(.headline)
                    }
                    .padding()
                    .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(32)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var totalFocusMinutes: Int {
        sessions.reduce(0) { $0 + ($1.actualSeconds / 60) }
    }

    private var summary: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Tempo di focus").foregroundStyle(.secondary)
                Text("\(totalFocusMinutes / 60)h \(totalFocusMinutes % 60)m")
                    .font(.system(size: 36, weight: .bold))
                Text("ultime sessioni registrate").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(sessions.count) sessioni")
                .padding(12)
                .background(.green.opacity(0.14), in: Capsule())
        }
        .padding(24)
        .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 20))
    }

    private var hourly: some View {
        VStack(alignment: .leading) {
            Text("Quando lavori").font(.headline)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<24, id: \.self) { hour in
                    let value = sessions.filter { Calendar.current.component(.hour, from: $0.startedAt) == hour }
                        .reduce(0) { $0 + $1.actualSeconds }

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.orange)
                        .frame(width: 14, height: CGFloat(max(4, min(130, value / 30))))
                }
            }
            .frame(height: 140, alignment: .bottom)
        }
        .padding(24)
        .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var list: [PomodoroSettings]

    var settings: PomodoroSettings {
        list.first ?? PomodoroSettings()
    }

    var body: some View {
        Form {
            Section("Sessioni") {
                Stepper("Durata: \(settings.focusMinutes) minuti", value: Bindable(settings).focusMinutes, in: 1...180)
                Stepper("Obiettivo giornaliero: \(settings.dailyGoal)", value: Bindable(settings).dailyGoal, in: 1...24)
            }

            Section("Pause") {
                Stepper("Pausa breve: \(settings.shortBreakMinutes) minuti", value: Bindable(settings).shortBreakMinutes, in: 1...60)
                Stepper("Pausa lunga: \(settings.longBreakMinutes) minuti", value: Bindable(settings).longBreakMinutes, in: 1...120)
                Stepper("Pausa lunga ogni \(settings.sessionsBeforeLongBreak) sessioni", value: Bindable(settings).sessionsBeforeLongBreak, in: 1...12)
            }

            Toggle("Avvia automaticamente la pausa", isOn: Bindable(settings).autoStartBreak)
        }
        .formStyle(.grouped)
        .padding(32)
        .navigationTitle("Impostazioni")
        .onAppear {
            if list.isEmpty {
                context.insert(settings)
                try? context.save()
            }
        }
    }
}
