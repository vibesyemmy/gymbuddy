import Foundation

enum PlannedSession {
    case gym, run, rest
}

enum Schedule {
    /// Mon/Wed/Fri gym, Tue/Thu/Sat run, Sunday rest.
    static func session(on date: Date, calendar: Calendar = .current) -> PlannedSession {
        switch calendar.component(.weekday, from: date) {
        case 2, 4, 6: return .gym
        case 3, 5, 7: return .run
        default: return .rest
        }
    }

    static func programWeek(start: Date, now: Date, calendar: Calendar = .current) -> Int {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: now)).day ?? 0
        return max(1, days / 7 + 1)
    }
}
