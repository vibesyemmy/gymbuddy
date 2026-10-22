import Foundation
import Observation
import UIKit

@Observable
final class RunSessionController {
    enum State { case idle, running, paused, finished }

    let week: RunWeek
    let tracker = LocationTracker()
    private(set) var state: State = .idle
    private(set) var engine: IntervalEngine
    private(set) var elapsed: TimeInterval = 0

    @ObservationIgnored private(set) var startedAt: Date?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var lastTick: Date?
    @ObservationIgnored private let cues = CueSpeaker()

    init(week: RunWeek) {
        self.week = week
        self.engine = IntervalEngine(segments: week.segments)
    }

    func start() {
        guard state == .idle else { return }
        tracker.requestPermissionIfNeeded()
        tracker.start()
        cues.prepare()
        UIApplication.shared.isIdleTimerDisabled = true
        startedAt = .now
        state = .running
        handle(engine.start())
        beginTimer()
    }

    func pause() {
        guard state == .running else { return }
        stopTimer()
        tracker.pause()
        state = .paused
        cues.say("Paused")
    }

    func resume() {
        guard state == .paused else { return }
        tracker.resume()
        state = .running
        cues.say("Resuming")
        beginTimer()
    }

    func finish() {
        guard state == .running || state == .paused else { return }
        stopTimer()
        tracker.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        cues.deactivateSoon()
        state = .finished
    }

    // MARK: Private

    private func beginTimer() {
        lastTick = .now
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.tick() }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let now = Date()
        let dt = now.timeIntervalSince(lastTick ?? now)
        lastTick = now
        elapsed += dt
        handle(engine.advance(by: dt))
    }

    private func handle(_ events: [EngineEvent]) {
        for event in events {
            switch event {
            case .started(let segment):
                cues.say(announcement(for: segment))
            case .finished:
                cues.say("Workout complete. Great job.")
                finish()
            }
        }
    }

    private func announcement(for segment: Segment) -> String {
        let minutes = Int(segment.duration) / 60
        let seconds = Int(segment.duration) % 60
        var spoken = minutes > 0 ? "\(minutes) minute\(minutes == 1 ? "" : "s")" : ""
        if seconds > 0 { spoken += (spoken.isEmpty ? "" : " ") + "\(seconds) seconds" }
        switch segment.phase {
        case .warmup: return "Warm up. Walk briskly for \(spoken)."
        case .run: return "Run for \(spoken)."
        case .walk: return "Walk for \(spoken)."
        case .cooldown: return "Cool down. Walk for \(spoken)."
        }
    }
}
