import SwiftUI
import SwiftData

struct RootView: View {
    @State private var tab: AppTab = .timer
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Foodapomo").font(.largeTitle.bold()).padding(.bottom, 20)
                ForEach(AppTab.allCases, id: \.self) { item in
                    Button { tab = item } label: { Label(item.rawValue, systemImage: icon(item)).frame(maxWidth: .infinity, alignment: .leading) }
                        .buttonStyle(.borderedProminent).tint(tab == item ? .orange : .clear).foregroundStyle(tab == item ? .white : .primary)
                }
                Spacer(); Text("Concentrati oggi, un pomodoro alla volta.").font(.caption).foregroundStyle(.secondary)
            }.padding(20).frame(minWidth: 190)
        } detail: {
            switch tab { case .timer: TimerView(); case .calendar: CalendarView(); case .history: HistoryView(); case .settings: SettingsView() }
        }.frame(minWidth: 900, minHeight: 620)
    }
    private func icon(_ tab: AppTab) -> String { switch tab { case .timer: "timer"; case .calendar: "calendar"; case .history: "chart.bar.xaxis"; case .settings: "gearshape" } }
}

struct TimerView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [PomodoroSettings]
    @StateObject private var engine = TimerEngine()
    @State private var title = ""
    var settings: PomodoroSettings { settingsList.first ?? PomodoroSettings() }
    var body: some View {
        VStack(spacing: 24) {
            HStack { VStack(alignment: .leading) { Text("Timer").font(.system(size: 34, weight: .bold)); Text("Concentrazione oggi, un passo alla volta.").foregroundStyle(.secondary) }; Spacer(); Text("Sessione \(engine.sessionNumber) di \(settings.dailyGoal)").font(.headline).padding(12).background(.orange.opacity(0.12), in: Capsule()) }
            Spacer()
            ZStack { Circle().stroke(.orange.opacity(0.14), lineWidth: 24); Circle().trim(from: 0, to: engine.progress).stroke(.orange, style: StrokeStyle(lineWidth: 24, lineCap: .round)).rotationEffect(.degrees(-90)); VStack { Text(engine.formatted).font(.system(size: 72, weight: .semibold, design: .rounded)); Text(engine.isBreak ? "Pausa" : (title.isEmpty ? "Pronto a concentrarti?" : title)).font(.title3).foregroundStyle(.secondary) } }.frame(width: 360, height: 360)
            HStack { TextField("Su cosa stai lavorando?", text: $title).textFieldStyle(.roundedBorder).frame(width: 300); Button(engine.running ? "Pausa" : "Inizia sessione") { engine.running ? engine.pause() : engine.start() }.buttonStyle(.borderedProminent).tint(.orange); Button("Termina") { engine.stop() }.buttonStyle(.bordered).disabled(!engine.running) }
            Spacer()
        }.padding(36).background(Color(nsColor: .windowBackgroundColor))
        .onAppear { setup() }
    }
    private func setup() { if settingsList.isEmpty { context.insert(settings); try? context.save() }; engine.configure(settings); engine.onFinish = { start, seconds, title, status in context.insert(FocusSession(startedAt: start, endedAt: Date(), plannedMinutes: settings.focusMinutes, actualSeconds: seconds, title: title, status: status)); try? context.save() } }
}

struct MenuBarView: View { @StateObject private var engine = TimerEngine(); var body: some View { VStack(spacing: 12) { Text("Foodapomo").font(.headline); Text(engine.formatted).font(.system(size: 36, weight: .medium, design: .rounded)); Button(engine.running ? "Pausa" : "Avvia") { engine.running ? engine.pause() : engine.start() }.buttonStyle(.borderedProminent).tint(.orange) }.padding(20).frame(width: 220) } }
