import MapKit
import SwiftData
import SwiftUI

struct RunView: View {
    let week: RunWeek
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var controller: RunSessionController

    init(week: RunWeek) {
        self.week = week
        _controller = State(initialValue: RunSessionController(week: week))
    }

    var body: some View {
        VStack(spacing: 24) {
            switch controller.state {
            case .idle: idleView
            case .running, .paused: activeView
            case .finished: summaryView
            }
        }
        .padding()
        .navigationTitle("Week \(week.number) run")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(controller.state == .running || controller.state == .paused)
    }

    // MARK: Idle

    private var idleView: some View {
        VStack(spacing: 20) {
            Text(week.title).font(.title2.bold()).multilineTextAlignment(.center)
            Text("5 min warm-up walk, intervals, 5 min cool-down · about \(week.totalMinutes) min")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Text("Run at a pace where you could still hold a conversation. Walk intervals are part of the plan, not a failure.")
                .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if controller.tracker.isDenied {
                Text("Location access is off, so distance can't be tracked. Enable it in Settings > GymBuddy > Location.")
                    .font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
            }
            Spacer()
            bigButton("Start", color: .green) { controller.start() }
        }
    }

    // MARK: Active

    private var activeView: some View {
        VStack(spacing: 20) {
            let phase = controller.engine.current?.phase
            Text((phase?.label ?? "").uppercased())
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(color(for: phase))
            Text(Format.clock(controller.engine.remainingInSegment))
                .font(.system(size: 88, weight: .bold, design: .rounded).monospacedDigit())
            if let next = controller.engine.next {
                Text("Next: \(next.phase.label) \(Format.clock(next.duration))")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack {
                metric("Time", Format.clock(controller.elapsed))
                metric("km", Format.km(controller.tracker.distanceMeters))
                metric("Pace /km", Format.pace(distance: controller.tracker.distanceMeters, duration: controller.elapsed))
            }
            if controller.state == .paused {
                bigButton("Resume", color: .green) { controller.resume() }
            } else {
                bigButton("Pause", color: .orange) { controller.pause() }
            }
            Button("End workout", role: .destructive) { controller.finish() }
        }
    }

    // MARK: Summary

    private var summaryView: some View {
        VStack(spacing: 20) {
            Text("Nice work").font(.largeTitle.bold())
            HStack {
                metric("Time", Format.clock(controller.elapsed))
                metric("km", Format.km(controller.tracker.distanceMeters))
                metric("Pace /km", Format.pace(distance: controller.tracker.distanceMeters, duration: controller.elapsed))
            }
            Map {
                if controller.tracker.route.count > 1 {
                    MapPolyline(coordinates: controller.tracker.route).stroke(.blue, lineWidth: 5)
                }
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            Spacer()
            bigButton("Save", color: .green) { save() }
            Button("Discard", role: .destructive) { dismiss() }
        }
    }

    // MARK: Helpers

    private func save() {
        let route = controller.tracker.route
        // Keep stored routes small: at most ~500 points.
        let stride = max(1, route.count / 500)
        let sampled = route.enumerated().filter { $0.offset % stride == 0 }.map(\.element)
        context.insert(RunLog(
            date: controller.startedAt ?? .now,
            week: week.number,
            distanceMeters: controller.tracker.distanceMeters,
            duration: controller.elapsed,
            routeLat: sampled.map(\.latitude),
            routeLon: sampled.map(\.longitude)
        ))
        dismiss()
    }

    private func color(for phase: RunPhase?) -> Color {
        switch phase {
        case .run: return .green
        case .walk, .warmup, .cooldown: return .blue
        case nil: return .primary
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack {
            Text(value).font(.title.bold().monospacedDigit())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func bigButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.title2.bold()).frame(maxWidth: .infinity).padding()
                .background(color, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.white)
        }
    }
}
