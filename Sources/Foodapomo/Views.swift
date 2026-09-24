import SwiftUI
import SwiftData

private enum FoodapomoStyle {
    static let cream = Color(red: 0.97, green: 0.94, blue: 0.88)
    static let card = Color.white.opacity(0.72)
    static let orange = Color(red: 0.88, green: 0.25, blue: 0.10)
    static let mutedOrange = Color(red: 0.98, green: 0.87, blue: 0.80)
    static let green = Color(red: 0.86, green: 0.92, blue: 0.79)
}

struct RootView: View {
    @State private var tab: AppTab = .timer

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    TomatoMark(size: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Foodapomo").font(.title2.bold())
                        Text("Concentrati oggi").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 24)

                ForEach(AppTab.allCases, id: \.self) { item in
                    Button { tab = item } label: {
                        Label(item.rawValue, systemImage: icon(item))
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(tab == item ? FoodapomoStyle.mutedOrange : .clear, in: RoundedRectangle(cornerRadius: 13))
                            .foregroundStyle(tab == item ? FoodapomoStyle.orange : .primary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
                Text("Un pomodoro alla volta.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
            }
            .padding(22)
            .frame(minWidth: 220)
            .background(FoodapomoStyle.cream)
        } detail: {
            Group {
                switch tab {
                case .timer: TimerView()
                case .calendar: CalendarView()
                case .history: HistoryView()
                case .settings: SettingsView()
                }
            }
            .background(FoodapomoStyle.cream)
        }
        .frame(minWidth: 980, minHeight: 680)
    }

    private func icon(_ tab: AppTab) -> String {
        switch tab {
        case .timer: return "timer"
        case .calendar: return "calendar"
        case .history: return "chart.bar.xaxis"
        case .settings: return "slider.horizontal.3"
        }
    }
}

struct TomatoMark: View {
    var size: CGFloat = 44
    var body: some View {
        ZStack {
            Circle().fill(FoodapomoStyle.orange).frame(width: size, height: size)
            Image(systemName: "leaf.fill").font(.system(size: size * 0.38)).foregroundStyle(.green).offset(y: -size * 0.38)
        }
        .frame(width: size, height: size)
    }
}

struct TimerView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [PomodoroSettings]
    @StateObject private var engine = TimerEngine()
    @State private var title = ""

    private var settings: PomodoroSettings { settingsList.first ?? PomodoroSettings() }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Timer").font(.system(size: 34, weight: .bold))
                    Text("Concentrazione oggi, un pomodoro alla volta.").foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<settings.dailyGoal, id: \.self) { index in
                        Circle().fill(index < engine.sessionNumber - 1 ? FoodapomoStyle.orange : Color.gray.opacity(0.18)).frame(width: 12, height: 12)
                    }
                }
                .padding(.top, 10)
            }

            HStack(spacing: 28) {
                timerCard
                VStack(alignment: .leading, spacing: 14) {
                    Text("Su cosa stai lavorando?").font(.headline)
                    TextField("Scrivi un'attività", text: $title)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                    Text("Sessione \(engine.sessionNumber) di \(settings.dailyGoal)")
                        .foregroundStyle(.secondary)
                    Button(engine.running ? "Pausa" : "Inizia sessione") {
                        engine.running ? engine.pause() : engine.start()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(FoodapomoStyle.orange)
                    .controlSize(.large)
                    Button("Termina sessione") { engine.stop() }
                        .buttonStyle(.bordered)
                        .disabled(!engine.running)
                }
                .frame(maxWidth: 280, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                Label("Prossima pausa", systemImage: "cup.and.saucer.fill")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Pausa breve tra \(max(1, settings.sessionsBeforeLongBreak - (engine.sessionNumber - 1) % settings.sessionsBeforeLongBreak)) sessioni")
                    .font(.subheadline.bold())
            }
            .padding(18)
            .background(FoodapomoStyle.green.opacity(0.65), in: RoundedRectangle(cornerRadius: 18))
        }
        .padding(34)
        .onAppear { setup() }
    }

    private var timerCard: some View {
        ZStack {
            Circle().stroke(Color.black.opacity(0.06), lineWidth: 22)
            Circle().trim(from: 0, to: engine.progress)
                .stroke(FoodapomoStyle.orange, style: StrokeStyle(lineWidth: 22, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: engine.progress)
            VStack(spacing: 8) {
                TomatoMark(size: 48)
                Text(engine.formatted).font(.system(size: 62, weight: .medium, design: .rounded))
                Text(engine.isBreak ? "Pausa" : (title.isEmpty ? "Pronto?" : title))
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(width: 390, height: 390)
        .padding(22)
        .background(.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 30))
    }

    private func setup() {
        if settingsList.isEmpty { context.insert(settings); try? context.save() }
        engine.configure(settings)
        engine.title = title
        engine.onFinish = { start, seconds, finishedTitle, status in
            context.insert(FocusSession(startedAt: start, endedAt: Date(), plannedMinutes: settings.focusMinutes, actualSeconds: seconds, title: finishedTitle, status: status))
            try? context.save()
        }
    }
}

struct MenuBarView: View {
    @StateObject private var engine = TimerEngine()
    var body: some View {
        VStack(spacing: 14) {
            HStack { TomatoMark(size: 26); Text("Foodapomo").font(.headline) }
            Text(engine.formatted).font(.system(size: 36, weight: .medium, design: .rounded))
            Button(engine.running ? "Pausa" : "Avvia") { engine.running ? engine.pause() : engine.start() }
                .buttonStyle(.borderedProminent).tint(FoodapomoStyle.orange)
        }
        .padding(20)
        .frame(width: 220)
        .background(FoodapomoStyle.cream)
    }
}
