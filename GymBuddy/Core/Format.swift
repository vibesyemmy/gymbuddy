import Foundation

enum Format {
    static func clock(_ t: TimeInterval) -> String {
        let s = max(0, Int(t.rounded(.down)))
        if s >= 3600 {
            return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
        }
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    static func km(_ meters: Double) -> String {
        String(format: "%.2f", meters / 1000)
    }

    /// Average pace as m:ss per km, or "--:--" until there is enough distance.
    static func pace(distance: Double, duration: TimeInterval) -> String {
        guard distance > 50 else { return "--:--" }
        return clock(duration / (distance / 1000))
    }

    static func kg(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }
}
