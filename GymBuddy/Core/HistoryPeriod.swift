import Foundation

/// Time window for browsing past activity on the History tab.
enum HistoryPeriod: String, CaseIterable, Identifiable {
    case thisWeek, thisMonth, last3Months, thisYear, all

    var id: Self { self }

    var title: String {
        switch self {
        case .thisWeek: "This week"
        case .thisMonth: "This month"
        case .last3Months: "Last 3 months"
        case .thisYear: "This year"
        case .all: "All time"
        }
    }

    /// Earliest date included, or nil for everything.
    var startDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .thisWeek: return calendar.dateInterval(of: .weekOfYear, for: .now)?.start
        case .thisMonth: return calendar.dateInterval(of: .month, for: .now)?.start
        case .last3Months: return calendar.date(byAdding: .month, value: -3, to: .now)
        case .thisYear: return calendar.dateInterval(of: .year, for: .now)?.start
        case .all: return nil
        }
    }
}
