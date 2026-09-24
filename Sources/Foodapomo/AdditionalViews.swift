import SwiftUI
import SwiftData
import EventKit

struct CalendarView: View {
    @StateObject private var service = CalendarService()
    @State private var date = Date()
    @State private var selected: EKEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Calendario").font(.system(size: 34, weight: .bold))
                    Text("Scegli un evento e lavora su quello.").foregroundStyle(.secondary)
                }
                Spacer()
                DatePicker("", selection: $date, displayedComponents: .date)
            }
            if !service.authorized {
                Spacer()
                ContentUnavailableView("Collega Apple Calendar", systemImage: "calendar.badge.plus", description: Text("Concedi l'accesso per vedere i tuoi eventi."))
                Button("Concedi accesso") { Task { await service.requestAccess() } }
                    .buttonStyle(.borderedProminent).tint(FoodapomoStyle.orange)
                Spacer()
            } else {
                List(service.events, id: \.eventIdentifier, selection: $selected) { event in
                    HStack(spacing: 14) {
                        Text(event.startDate, style: .time).font(.headline).frame(width: 65, alignment: .leading)
                        Circle().fill(FoodapomoStyle.orange).frame(width: 9, height: 9)
                        VStack(alignment: .leading) {
                            Text(event.title).font(.headline)
                            Text(event.location ?? "Evento calendario").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(selected == event ? FoodapomoStyle.mutedOrange : .clear, in: RoundedRectangle(cornerRadius: 14))
                }
                .scrollContentBackground(.hidden)
                Button("Inizia sessione su questo evento") {}
                    .buttonStyle(.borderedProminent).tint(FoodapomoStyle.orange).disabled(selected == nil)
            }
        }
        .padding(34)
        .onAppear { Task { await service.requestAccess(); service.loadEvents(for: date) } }
        .onChange(of: date) { _, value in service.loadEvents(for: value) }
    }
}

struct HistoryView: View {
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Storico").font(.system(size: 34, weight: .bold))
                        Text("Il tuo percorso, un pomodoro alla volta.").foregroundStyle(.secondary)
                    }
                    Spacer(); Text("Ultimi 30 giorni").font(.subheadline).padding(10).background(.white.opacity(0.6), in: Capsule())
                }
                summary
                HStack(spacing: 18) { hourly; weekdayChart }
                Text("Sessioni recenti").font(.title2.bold())
                ForEach(Array(sessions.prefix(20))) { session in
                    HStack(spacing: 14) {
                        Image(systemName: session.status == SessionStatus.completed ? "checkmark.circle.fill" : "pause.circle.fill").font(.title3).foregroundStyle(FoodapomoStyle.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.title).font(.headline)
                            Text("\(session.startedAt.formatted(date: .abbreviated, time: .shortened)) – \(session.endedAt.formatted(date: .omitted, time: .shortened))").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(); Text("\(session.actualSeconds / 60) min").font(.headline)
                    }
                    .padding(15).background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(34)
        }
    }

    private var totalMinutes: Int { sessions.reduce(0) { $0 + $1.actualSeconds / 60 } }
    private var summary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tempo di focus").foregroundStyle(.secondary)
                Text("\(totalMinutes / 60)h \(totalMinutes % 60)m").font(.system(size: 38, weight: .bold))
                Text("totale registrato").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text("↑ +18%").font(.headline).foregroundStyle(.green)
                Text("rispetto alla media mensile").font(.caption).foregroundStyle(.secondary)
            }
            .padding(12).background(.green.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
        }
        .padding(24).background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 22))
    }

    private var hourly: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Produttività durante la giornata").font(.headline)
            HStack(alignment: .bottom, spacing: 7) {
                ForEach(0..<24, id: \.self) { hour in
                    let value = sessions.filter { Calendar.current.component(.hour, from: $0.startedAt) == hour }.reduce(0) { $0 + $1.actualSeconds }
                    RoundedRectangle(cornerRadius: 4).fill(FoodapomoStyle.orange).frame(width: 10, height: CGFloat(max(5, min(110, value / 30))))
                }
            }.frame(height: 120, alignment: .bottom)
            Text("6          9          12          15          18          21").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading).background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 20))
    }

    private var weekdayChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessioni giornaliere").font(.headline)
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<7, id: \.self) { _ in RoundedRectangle(cornerRadius: 4).fill(FoodapomoStyle.orange).frame(width: 20, height: 44) }
            }.frame(height: 120, alignment: .bottom)
            Text("Lun     Mar     Mer     Gio     Ven     Sab     Dom").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading).background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var list: [PomodoroSettings]
    private var settings: PomodoroSettings { list.first ?? PomodoroSettings() }

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
        .formStyle(.grouped).padding(34).navigationTitle("Impostazioni")
        .onAppear { if list.isEmpty { context.insert(settings); try? context.save() } }
    }
}
