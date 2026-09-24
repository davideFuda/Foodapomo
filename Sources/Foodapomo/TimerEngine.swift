import Foundation
import UserNotifications

@MainActor final class TimerEngine: ObservableObject {
    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var running = false
    @Published private(set) var isBreak = false
    @Published private(set) var sessionNumber = 1
    @Published var title = ""

    private var timer: Timer?
    private var startedAt: Date?
    private var plannedSeconds = 0
    private var settings: PomodoroSettings?
    var onFinish: ((Date, Int, String, String) -> Void)?

    func configure(_ settings: PomodoroSettings) {
        self.settings = settings
        if !running && remaining == 0 {
            plannedSeconds = max(1, settings.focusMinutes * 60)
            remaining = TimeInterval(plannedSeconds)
        }
    }

    func start() {
        guard remaining > 0 else { return }
        if startedAt == nil { startedAt = Date() }
        if plannedSeconds == 0 { plannedSeconds = max(1, Int(remaining.rounded())) }
        running = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func pause() {
        running = false
        timer?.invalidate()
        timer = nil
    }

    func stop() {
        guard let start = startedAt else { pause(); return }
        let elapsed = max(0, plannedSeconds - Int(remaining.rounded()))
        if elapsed > 0 {
            onFinish?(start, elapsed, title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Sessione di focus" : title, SessionStatus.interrupted)
        }
        resetFocus()
        pause()
    }

    func resetFocus() {
        isBreak = false
        startedAt = nil
        plannedSeconds = max(1, (settings?.focusMinutes ?? 25) * 60)
        remaining = TimeInterval(plannedSeconds)
    }

    func startBreak() {
        pause()
        isBreak = true
        startedAt = nil
        plannedSeconds = max(1, (settings?.shortBreakMinutes ?? 5) * 60)
        remaining = TimeInterval(plannedSeconds)
        start()
    }

    private func tick() {
        guard running else { return }
        remaining = max(0, remaining - 1)
        guard remaining <= 0 else { return }

        pause()
        if !isBreak, let start = startedAt {
            let sessionTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Sessione di focus" : title
            onFinish?(start, plannedSeconds, sessionTitle, SessionStatus.completed)
            sessionNumber += 1
        }
        sendNotification()
        resetFocus()
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = isBreak ? "Pausa terminata" : "Sessione completata"
        content.body = isBreak ? "Pronto per ricominciare?" : "Ottimo lavoro!"
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    var formatted: String {
        let seconds = max(0, Int(remaining))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var progress: Double {
        guard plannedSeconds > 0 else { return 0 }
        return min(1, max(0, 1 - remaining / Double(plannedSeconds)))
    }
}
