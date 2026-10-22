import Foundation

enum RunPhase: String, Equatable {
    case warmup, run, walk, cooldown

    var label: String {
        switch self {
        case .warmup: return "Warm up"
        case .run: return "Run"
        case .walk: return "Walk"
        case .cooldown: return "Cool down"
        }
    }
}

struct Segment: Equatable {
    let phase: RunPhase
    let duration: TimeInterval
}

enum EngineEvent: Equatable {
    case started(Segment)
    case finished
}

/// Pure state machine that walks through a list of timed segments.
/// It knows nothing about clocks: callers feed it elapsed time.
struct IntervalEngine {
    let segments: [Segment]
    private(set) var index = 0
    private(set) var elapsedInSegment: TimeInterval = 0
    private(set) var isFinished: Bool

    init(segments: [Segment]) {
        self.segments = segments
        self.isFinished = segments.isEmpty
    }

    var current: Segment? { index < segments.count ? segments[index] : nil }
    var next: Segment? { index + 1 < segments.count ? segments[index + 1] : nil }
    var remainingInSegment: TimeInterval { max(0, (current?.duration ?? 0) - elapsedInSegment) }
    var totalDuration: TimeInterval { segments.reduce(0) { $0 + $1.duration } }

    mutating func start() -> [EngineEvent] {
        if let current { return [.started(current)] }
        return [.finished]
    }

    mutating func advance(by dt: TimeInterval) -> [EngineEvent] {
        guard !isFinished else { return [] }
        var events: [EngineEvent] = []
        var remaining = dt
        while remaining > 0, let segment = current {
            let left = segment.duration - elapsedInSegment
            if remaining < left {
                elapsedInSegment += remaining
                remaining = 0
            } else {
                remaining -= left
                index += 1
                elapsedInSegment = 0
                if let next = current {
                    events.append(.started(next))
                } else {
                    isFinished = true
                    events.append(.finished)
                }
            }
        }
        return events
    }
}
