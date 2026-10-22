import Foundation

struct Exercise: Identifiable, Hashable {
    let name: String
    let sets: Int
    let repsLow: Int
    let repsHigh: Int
    let restSeconds: Int
    var isBodyweight = false
    var unit = "reps"
    var increment = 2.5

    var id: String { name }
    var target: String {
        repsLow == repsHigh ? "\(sets) × \(repsHigh)" : "\(sets) × \(repsLow)–\(repsHigh)"
    }
}

struct GymDay: Identifiable, Hashable {
    let key: String
    let title: String
    let exercises: [Exercise]
    var id: String { key }
}

/// Three full-body sessions that rotate (A → B → C → A …), each with direct ab work.
/// Progression: when you hit the top of the rep range on every set, add weight next time.
enum GymPlan {
    static let days: [GymDay] = [
        GymDay(key: "A", title: "Full body A", exercises: [
            Exercise(name: "Back squat", sets: 3, repsLow: 6, repsHigh: 8, restSeconds: 120),
            Exercise(name: "Bench press", sets: 3, repsLow: 6, repsHigh: 8, restSeconds: 120),
            Exercise(name: "Barbell row", sets: 3, repsLow: 8, repsHigh: 10, restSeconds: 90),
            Exercise(name: "Plank", sets: 3, repsLow: 30, repsHigh: 45, restSeconds: 60, isBodyweight: true, unit: "sec"),
        ]),
        GymDay(key: "B", title: "Full body B", exercises: [
            Exercise(name: "Romanian deadlift", sets: 3, repsLow: 8, repsHigh: 10, restSeconds: 120),
            Exercise(name: "Overhead press", sets: 3, repsLow: 6, repsHigh: 8, restSeconds: 90),
            Exercise(name: "Lat pulldown", sets: 3, repsLow: 8, repsHigh: 12, restSeconds: 90),
            Exercise(name: "Hanging knee raise", sets: 3, repsLow: 10, repsHigh: 15, restSeconds: 60, isBodyweight: true),
        ]),
        GymDay(key: "C", title: "Full body C", exercises: [
            Exercise(name: "Leg press", sets: 3, repsLow: 10, repsHigh: 12, restSeconds: 90, increment: 5),
            Exercise(name: "Incline dumbbell press", sets: 3, repsLow: 8, repsHigh: 12, restSeconds: 90, increment: 2),
            Exercise(name: "Seated cable row", sets: 3, repsLow: 10, repsHigh: 12, restSeconds: 90),
            Exercise(name: "Cable crunch", sets: 3, repsLow: 12, repsHigh: 15, restSeconds: 60),
        ]),
    ]
}
