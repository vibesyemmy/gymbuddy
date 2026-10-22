import SwiftData
import SwiftUI

/// Where a session card can lead: its detail screen, or straight into the workout.
private enum TodayRoute: Hashable {
    case cardioDetail
    case cardioActive(CardioMode)
    case gymDetail(String)
    case gymActive(String)
}

struct TodayView: View {
    @AppStorage("programStart") private var programStart: Double = 0
    @Query(sort: \GymLog.date, order: .reverse) private var gymLogs: [GymLog]
    @Query(sort: \RunLog.date, order: .reverse) private var runLogs: [RunLog]
    @State private var path: [TodayRoute] = []
    /// What the walk/run card's play button starts; changed on its detail screen.
    @AppStorage("cardioMode") private var cardioMode: CardioMode = .intervals

    private var week: Int {
        Schedule.programWeek(start: Date(timeIntervalSince1970: programStart), now: .now)
    }
    private var runWeek: RunWeek { RunPlan.week(week) }
    private var nextGymDay: GymDay { GymPlan.days[gymLogs.count % GymPlan.days.count] }

    private func isThisWeek(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: .now, toGranularity: .weekOfYear)
    }

    private var weekGym: Int { gymLogs.filter { isThisWeek($0.date) }.count }
    private var weekRuns: [RunLog] { runLogs.filter { $0.isRunOrWalk && isThisWeek($0.date) } }

    /// Monday-first dots for the current week, filled when anything was logged that day.
    private var weekDays: [(letter: String, done: Bool, isToday: Bool)] {
        let calendar = Calendar.current
        guard let start = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else { return [] }
        let logged = (gymLogs.map(\.date) + runLogs.map(\.date)).filter(isThisWeek)
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let letter = String(day.formatted(.dateTime.weekday(.narrow)))
            return (letter, logged.contains { calendar.isDate($0, inSameDayAs: day) }, calendar.isDateInToday(day))
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ThemedScroll {
                header
                weekStrip
                statTiles
                sessionsSection
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: TodayRoute.self) { route in
                // Detail and workout screens use the full screen, with their own Start and bottom bars.
                destination(for: route)
                    .toolbar(.hidden, for: .tabBar)
            }
        }
    }

    /// The Start buttons replace the whole path, so finishing or leaving a workout returns to Today
    /// rather than to the detail screen.
    @ViewBuilder
    private func destination(for route: TodayRoute) -> some View {
        switch route {
        case .cardioDetail:
            CardioDetailView(week: runWeek, mode: $cardioMode) { mode in path = [.cardioActive(mode)] }
        case .cardioActive(let mode):
            RunView(week: runWeek, mode: mode, autoStart: true)
        case .gymDetail(let key):
            if let day = GymPlan.days.first(where: { $0.key == key }) {
                GymDetailView(day: day) { path = [.gymActive(key)] }
            }
        case .gymActive(let key):
            if let day = GymPlan.days.first(where: { $0.key == key }) {
                GymView(day: day)
            }
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Week \(week) of your plan")
                .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
            Text(headline)
                .font(.system(size: 24, weight: .semibold)).foregroundStyle(Theme.textPrimary)
        }
        .padding(.top, 4)
    }

    private var headline: String {
        let done = weekGym + weekRuns.count
        return done == 0 ? "Let's get this week going!" : "You've logged \(done) \(done == 1 ? "session" : "sessions") this week."
    }

    private var weekStrip: some View {
        HStack {
            ForEach(Array(weekDays.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(day.done ? Theme.blue : Theme.card)
                            .frame(width: 30, height: 30)
                        Circle()
                            .strokeBorder(day.isToday ? Theme.blue : Theme.divider, lineWidth: day.isToday ? 2 : 1)
                            .frame(width: 30, height: 30)
                        if day.done {
                            Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                        }
                    }
                    Text(day.letter).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var statTiles: some View {
        HStack(spacing: 8) {
            StatTile(label: "Gym", value: "\(weekGym)", unit: "/ 3")
            StatTile(label: "Walk / run", value: "\(weekRuns.count)", unit: "/ 3")
            StatTile(label: "Walk / run km", value: Format.km(weekRuns.reduce(0) { $0 + $1.distanceMeters }))
        }
    }

    // MARK: Sessions

    /// All sessions in one place: the walk/run card is the big one, the gym days sit below as squares.
    /// Tapping a card opens its details; its play button starts the workout straight away.
    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                SectionLabel("Sessions")
                Text("Walk, run or lift. Pick whatever suits today.")
                    .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
            }
            walkRunCard
            HStack(spacing: 8) {
                ForEach(GymPlan.days) { day in
                    gymCard(day)
                }
            }
            Text("Tap a card for the full list. Tap the play button to start right away.")
                .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
        }
    }

    private var walkRunCard: some View {
        ZStack(alignment: .bottomTrailing) {
            Button { path.append(.cardioDetail) } label: {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        SectionLabel("Walk / run").foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Image(systemName: cardioMode.icon).foregroundStyle(Theme.mint)
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cardioMode == .intervals ? "Week \(runWeek.number)" : "Free \(cardioMode.title.lowercased())")
                            .font(.system(size: 28, weight: .semibold)).foregroundStyle(.white)
                        Text(cardioMode == .intervals ? "\(runWeek.title) · \(runWeek.totalMinutes) min" : "Your own pace · tracked by GPS")
                            .font(.system(size: 14)).foregroundStyle(.white.opacity(0.7))
                    }
                    // Leaves room for the play button.
                    .padding(.trailing, 56)
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
                .background(Color(hex: 0x1B1D21), in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the walk and run options")

            PlayButton(label: cardioMode == .intervals ? "Start week \(runWeek.number) intervals" : "Start free \(cardioMode.title.lowercased())", size: 44) {
                path.append(.cardioActive(cardioMode))
            }
            .padding(8)
        }
    }

    private func gymCard(_ day: GymDay) -> some View {
        let isHighlighted = day.key == nextGymDay.key
        return ZStack(alignment: .topTrailing) {
            Button { path.append(.gymDetail(day.key)) } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Image(systemName: "dumbbell.fill").font(.system(size: 18)).foregroundStyle(Theme.red)
                    Spacer(minLength: 8)
                    if isHighlighted {
                        Text("NEXT")
                            .font(.system(size: 10, weight: .semibold)).tracking(1).foregroundStyle(Theme.red)
                    }
                    Text(day.title)
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                        .lineLimit(2).multilineTextAlignment(.leading)
                    Text("\(day.exercises.count) exercises")
                        .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .aspectRatio(1, contentMode: .fit)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).strokeBorder(isHighlighted ? Theme.red : .clear, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the full exercise list")

            PlayButton(label: "Start \(day.title)", size: 34) { path.append(.gymActive(day.key)) }
                .padding(4)
        }
    }
}

/// Round red play button. Its tap area is at least 44 points even when the circle is smaller.
private struct PlayButton: View {
    let label: String
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "play.fill")
                .font(.system(size: size * 0.4, weight: .bold)).foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Theme.red, in: Circle())
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
