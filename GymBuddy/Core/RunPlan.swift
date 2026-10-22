import Foundation

/// One week of the run/walk progression. Every run that week uses the same structure.
struct RunWeek: Identifiable {
    let number: Int
    let runSeconds: Int
    let walkSeconds: Int
    let reps: Int

    var id: Int { number }

    var title: String {
        if reps == 1 { return "Run \(runSeconds / 60) min nonstop" }
        return "\(reps) × (run \(Format.clock(Double(runSeconds))) / walk \(Format.clock(Double(walkSeconds))))"
    }

    var segments: [Segment] {
        var result = [Segment(phase: .warmup, duration: 300)]
        for rep in 0..<reps {
            result.append(Segment(phase: .run, duration: Double(runSeconds)))
            if walkSeconds > 0, rep < reps - 1 {
                result.append(Segment(phase: .walk, duration: Double(walkSeconds)))
            }
        }
        result.append(Segment(phase: .cooldown, duration: 300))
        return result
    }

    var totalMinutes: Int {
        Int((segments.reduce(0) { $0 + $1.duration } / 60).rounded())
    }
}

enum RunPlan {
    /// Starts from your walking base and builds to 30 minutes of continuous running.
    static let weeks: [RunWeek] = [
        RunWeek(number: 1, runSeconds: 60, walkSeconds: 120, reps: 8),
        RunWeek(number: 2, runSeconds: 90, walkSeconds: 120, reps: 7),
        RunWeek(number: 3, runSeconds: 120, walkSeconds: 90, reps: 6),
        RunWeek(number: 4, runSeconds: 180, walkSeconds: 90, reps: 5),
        RunWeek(number: 5, runSeconds: 300, walkSeconds: 90, reps: 4),
        RunWeek(number: 6, runSeconds: 480, walkSeconds: 90, reps: 3),
        RunWeek(number: 7, runSeconds: 720, walkSeconds: 90, reps: 2),
        RunWeek(number: 8, runSeconds: 1500, walkSeconds: 0, reps: 1),
        RunWeek(number: 9, runSeconds: 1800, walkSeconds: 0, reps: 1),
    ]

    static func week(_ number: Int) -> RunWeek {
        weeks[min(max(number, 1), weeks.count) - 1]
    }
}
