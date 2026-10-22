import Foundation

/// How a walk/run session is done. Walks and runs count the same toward the weekly goal.
enum CardioMode: String, CaseIterable, Identifiable, Hashable {
    /// The run/walk interval plan for the current week, for a mix of both.
    case intervals
    /// Open-ended walk at your own pace.
    case walk
    /// Open-ended run at your own pace.
    case run

    var id: Self { self }

    var title: String {
        switch self {
        case .intervals: "Intervals"
        case .walk: "Walk"
        case .run: "Run"
        }
    }

    var icon: String {
        switch self {
        case .intervals, .run: "figure.run"
        case .walk: "figure.walk"
        }
    }

    /// Label saved with the session, matching what Health and Strava imports use.
    var activityLabel: String {
        switch self {
        case .intervals, .run: "Run"
        case .walk: "Walk"
        }
    }

    var isOpenEnded: Bool { self != .intervals }
}
