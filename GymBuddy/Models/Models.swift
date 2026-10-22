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

    init(date: Date, week: Int, distanceMeters: Double, duration: TimeInterval, routeLat: [Double], routeLon: [Double]) {
        self.date = date
        self.week = week
        self.distanceMeters = distanceMeters
        self.duration = duration
        self.routeLat = routeLat
        self.routeLon = routeLon
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
