import Foundation
import SwiftData

@Model
final class RunLog {
    var date: Date
    var week: Int
    var distanceMeters: Double
    var duration: TimeInterval
    var routeLat: [Double]
    var routeLon: [Double]
    /// Identifier of the outside record (Health workout UUID, "strava-<id>") this run was imported from;
    /// nil for runs recorded in the app. Renamed from healthKitID, so keep the original name for migration.
    @Attribute(originalName: "healthKitID") var sourceID: String?
    /// "Run", "Walk", "Ride", "Strength"…; nil for runs recorded in the app and entries imported before this existed.
    var activity: String?

    /// True for the run/walk sessions the training plan is built around.
    var isRunOrWalk: Bool { activity == nil || activity == "Run" || activity == "Walk" }

    init(date: Date, week: Int, distanceMeters: Double, duration: TimeInterval, routeLat: [Double], routeLon: [Double], sourceID: String? = nil, activity: String? = nil) {
        self.date = date
        self.week = week
        self.distanceMeters = distanceMeters
        self.duration = duration
        self.routeLat = routeLat
        self.routeLon = routeLon
        self.sourceID = sourceID
        self.activity = activity
    }
}

extension RunLog {
    /// One-line summary such as "5.02 km · 30:00 · 5:58 /km". Pace is only shown for runs and walks.
    var summary: String {
        var parts: [String] = []
        if distanceMeters > 0 { parts.append("\(Format.km(distanceMeters)) km") }
        parts.append(Format.clock(duration))
        if isRunOrWalk && distanceMeters > 0 {
            parts.append("\(Format.pace(distance: distanceMeters, duration: duration)) /km")
        }
        return parts.joined(separator: " · ")
    }
}

@Model
final class GymLog {
    var date: Date
    var dayKey: String
    var title: String
    @Relationship(deleteRule: .cascade, inverse: \SetLog.log) var sets: [SetLog] = []

    init(date: Date, dayKey: String, title: String) {
        self.date = date
        self.dayKey = dayKey
        self.title = title
    }
}

@Model
final class SetLog {
    var exercise: String
    var setNumber: Int
    var weightKg: Double
    var reps: Int
    var log: GymLog?

    init(exercise: String, setNumber: Int, weightKg: Double, reps: Int) {
        self.exercise = exercise
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
    }
}

@Model
final class BodyEntry {
    var date: Date
    var weightKg: Double
    var waistCm: Double?
    var neckCm: Double?

    init(date: Date = .now, weightKg: Double, waistCm: Double?, neckCm: Double? = nil) {
        self.date = date
        self.weightKg = weightKg
        self.waistCm = waistCm
        self.neckCm = neckCm
    }
}
