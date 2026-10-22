import MapKit
import SwiftData
import SwiftUI

struct RunView: View {
    let week: RunWeek
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var controller: RunSessionController
    /// Begins the session as soon as the screen appears, instead of waiting for the Start button.
    private let autoStart: Bool
    private let mode: CardioMode

    init(week: RunWeek, mode: CardioMode = .intervals, autoStart: Bool = false) {
        self.week = week
        self.mode = mode
        self.autoStart = autoStart
        _controller = State(initialValue: RunSessionController(week: week, mode: mode))
    }

    var body: some View {
        VStack(spacing: 24) {
            switch controller.state {
            case .idle:
                // When auto-starting, show nothing for the instant before the session begins.
                if autoStart { Color.clear } else { idleView }
            case .running, .paused: activeView
            case .finished: summaryView
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.page.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .navigationTitle(mode == .intervals ? "Week \(week.number)" : mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(controller.state == .running || controller.state == .paused)
        .onAppear {
            if autoStart && controller.state == .idle { controller.start() }
        }
    }

    // MARK: Idle

    private var idleView: some View {
        VStack(spacing: 16) {
            Card {
                SectionLabel("Run / walk intervals")
                Text(week.title).font(.system(size: 24, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text("5 min warm-up walk, intervals, 5 min cool-down · about \(week.totalMinutes) min")
                    .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                Text("Run at a pace where you could still hold a conversation. Walk intervals are part of the plan, not a failure.")
                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.tile, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
            }
            if controller.tracker.isDenied {
                Text("Location access is off, so distance can't be tracked. Enable it in Settings > GymBuddy > Location.")
                    .font(.system(size: 13)).foregroundStyle(Theme.red).multilineTextAlignment(.center)
            }
            Spacer()
            PrimaryButton(title: "Start", icon: "play.fill") { controller.start() }
        }
    }

    // MARK: Active

    /// The phase shown in the header: the current segment, or a steady walk/run for open-ended sessions.
    private var displayPhase: RunPhase? {
        switch mode {
        case .intervals: controller.engine.current?.phase
        case .walk: .walk
        case .run: .run
        }
    }

    private var activeView: some View {
        let engine = controller.engine
        let phase = displayPhase
        let duration = engine.current?.duration ?? 1
        let progress = 1 - engine.remainingInSegment / max(duration, 1)
        return VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text((phase?.label ?? "").uppercased())
                        .font(.system(size: 22, weight: .semibold)).tracking(1.5)
                        .foregroundStyle(color(for: phase))
                    if let next = engine.next {
                        Text("Next: \(next.phase.label) \(Format.clock(next.duration))")
                            .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                RoundIconButton(icon: "stop.fill", fill: Theme.tile) { controller.finish() }
                if controller.state == .paused {
                    RoundIconButton(icon: "play.fill", fill: Theme.red) { controller.resume() }
                } else {
                    RoundIconButton(icon: "pause.fill", fill: Theme.red) { controller.pause() }
                }
            }

            if mode.isOpenEnded {
                // No segments to count down, so show time so far.
                Text(Format.clock(controller.elapsed))
                    .font(.system(size: 84, weight: .light)).monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                    .frame(height: 230)
            } else {
                ZStack {
                    ArcProgress(progress: progress, tint: color(for: phase))
                    Text(Format.clock(engine.remainingInSegment))
                        .font(.system(size: 84, weight: .light)).monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                        .offset(y: 20)
                }
                .frame(height: 230)
            }

            Spacer(minLength: 0)

            Card {
                HStack {
                    metric("Time", Format.clock(controller.elapsed))
                    metric("km", Format.km(controller.tracker.distanceMeters))
                    metric("Pace /km", Format.pace(distance: controller.tracker.distanceMeters, duration: controller.elapsed))
                }
            }
        }
    }

    // MARK: Summary

    private var summaryView: some View {
        VStack(spacing: 16) {
            Card {
                SectionLabel("Workout complete")
                Text("Nice work").font(.system(size: 28, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                HStack {
                    metric("Time", Format.clock(controller.elapsed))
                    metric("km", Format.km(controller.tracker.distanceMeters))
                    metric("Pace /km", Format.pace(distance: controller.tracker.distanceMeters, duration: controller.elapsed))
                }
            }
            Map {
                if controller.tracker.route.count > 1 {
                    MapPolyline(coordinates: controller.tracker.route).stroke(Theme.red, lineWidth: 5)
                }
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            Spacer()
            PrimaryButton(title: "Save", icon: "checkmark") { save() }
            Button("Discard") { dismiss() }
                .font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.textSecondary)
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
            // Open-ended walks and runs aren't part of a plan week.
            week: mode == .intervals ? week.number : 0,
            distanceMeters: controller.tracker.distanceMeters,
            duration: controller.elapsed,
            routeLat: sampled.map(\.latitude),
            routeLon: sampled.map(\.longitude),
            activity: mode.activityLabel
        ))
        dismiss()
    }

    private func color(for phase: RunPhase?) -> Color {
        switch phase {
        case .run: return Theme.mint
        case .walk, .warmup, .cooldown: return Theme.blue
        case nil: return Theme.textPrimary
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 24, weight: .medium)).monospacedDigit().foregroundStyle(Theme.textPrimary)
            Text(label).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Open-bottom arc that fills clockwise, like Peloton's exercise timer.
private struct ArcProgress: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height * 1.6)
            ZStack {
                arc(1).stroke(Theme.divider, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                arc(min(max(progress, 0.001), 1)).stroke(tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
            }
            .frame(width: side, height: side)
            .position(x: proxy.size.width / 2, y: side / 2 + 5)
        }
    }

    /// 200° sweep from lower-left over the top to lower-right.
    private func arc(_ fraction: Double) -> some Shape {
        ArcShape(fraction: fraction)
    }
}

private struct ArcShape: Shape {
    var fraction: Double
    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let start = Angle.degrees(170)
        let sweep = 200.0
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2,
                    startAngle: start, endAngle: start + .degrees(sweep * fraction), clockwise: false)
        return path
    }
}
