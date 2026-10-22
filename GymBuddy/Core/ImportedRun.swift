import Foundation

/// A past activity (run, walk, ride, gym session…) from an outside source (Health, Strava) that hasn't been saved yet.
struct ImportedRun: Sendable {
    let sourceID: String
    /// Short label such as "Run", "Walk", "Ride" or "Strength".
    let activity: String
    let date: Date
    let distanceMeters: Double
    let duration: TimeInterval
}

/// How far back to import runs from.
enum ImportPeriod: String, CaseIterable, Identifiable {
    case month, threeMonths, sixMonths, year, all

    var id: Self { self }

    var title: String {
        switch self {
        case .month: "Last month"
        case .threeMonths: "Last 3 months"
        case .sixMonths: "Last 6 months"
        case .year: "Last year"
        case .all: "All time"
        }
    }

    /// Earliest date to import, or nil for everything.
    var startDate: Date? {
        let months: Int
        switch self {
        case .month: months = 1
        case .threeMonths: months = 3
        case .sixMonths: months = 6
        case .year: months = 12
        case .all: return nil
        }
        return Calendar.current.date(byAdding: .month, value: -months, to: .now)
    }
}

extension ImportedRun {
    /// Drops runs that are already saved (same source ID) or that match a saved run's start time and
    /// distance, e.g. a Strava run that also synced to Health, or one recorded in this app.
    static func newRuns(_ runs: [ImportedRun], existing: [RunLog]) -> [ImportedRun] {
        let knownIDs = Set(existing.compactMap(\.sourceID))
        var seen = existing.map { (date: $0.date, meters: $0.distanceMeters) }
        var fresh: [ImportedRun] = []
        for run in runs where !knownIDs.contains(run.sourceID) {
            let isDuplicate = seen.contains {
                abs($0.date.timeIntervalSince(run.date)) < 120
                    && abs($0.meters - run.distanceMeters) < max(100, run.distanceMeters * 0.05)
            }
            if isDuplicate { continue }
            fresh.append(run)
            seen.append((run.date, run.distanceMeters))
        }
        return fresh
    }
}
