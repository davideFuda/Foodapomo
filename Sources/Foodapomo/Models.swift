import Foundation
import SwiftData

@Model final class FocusSession {
    var startedAt: Date
    var endedAt: Date
    var plannedMinutes: Int
    var actualSeconds: Int
    var title: String
    var status: String
    var calendarEventID: String?

    init(startedAt: Date, endedAt: Date, plannedMinutes: Int, actualSeconds: Int, title: String, status: String = "completed", calendarEventID: String? = nil) {
        self.startedAt = startedAt; self.endedAt = endedAt; self.plannedMinutes = plannedMinutes
        self.actualSeconds = actualSeconds; self.title = title; self.status = status; self.calendarEventID = calendarEventID
    }
}

@Model final class PomodoroSettings {
    var focusMinutes: Int = 25
    var shortBreakMinutes: Int = 5
    var longBreakMinutes: Int = 15
    var sessionsBeforeLongBreak: Int = 4
    var dailyGoal: Int = 6
    var autoStartBreak: Bool = false
    init() {}
}

enum AppTab: String, CaseIterable { case timer = "Timer", calendar = "Calendario", history = "Storico", settings = "Impostazioni" }
enum SessionStatus { static let completed = "completed"; static let interrupted = "interrupted" }
