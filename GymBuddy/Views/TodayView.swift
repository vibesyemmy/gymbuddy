import SwiftData
import SwiftUI

struct TodayView: View {
    @AppStorage("programStart") private var programStart: Double = 0
    @Query(sort: \GymLog.date, order: .reverse) private var gymLogs: [GymLog]
    @Query(sort: \RunLog.date, order: .reverse) private var runLogs: [RunLog]

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
        NavigationStack {
            ThemedScroll {
                header
                weekStrip
                statTiles
                todayCard
                sessionsCard
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
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
            StatTile(label: "Runs", value: "\(weekRuns.count)", unit: "/ 3")
            StatTile(label: "Run km", value: Format.km(weekRuns.reduce(0) { $0 + $1.distanceMeters }))
        }
    }

    @ViewBuilder
    private var todayCard: some View {
        switch Schedule.session(on: .now) {
        case .gym:
            NavigationLink { GymView(day: nextGymDay) } label: {
                featureCard(kind: "Gym day", title: nextGymDay.title,
                            detail: "\(nextGymDay.exercises.count) exercises · about 45 min", icon: "dumbbell.fill", tint: Theme.red)
            }
            .buttonStyle(.plain)
        case .run:
            NavigationLink { RunView(week: runWeek) } label: {
                featureCard(kind: "Run day", title: "Week \(runWeek.number) run",
                            detail: "\(runWeek.title) · \(runWeek.totalMinutes) min", icon: "figure.run", tint: Theme.mint)
            }
            .buttonStyle(.plain)
        case .rest:
            Card {
                SectionLabel("Rest day")
                Text("Easy walk if you feel like it.")
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text("Recovery is when you grow.")
                    .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    /// Dark hero card, the Today equivalent of Peloton's "Up next in your program".
    private func featureCard(kind: String, title: String, detail: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionLabel(kind).foregroundStyle(.white.opacity(0.7))
                Spacer()
                Image(systemName: icon).foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 24, weight: .semibold)).foregroundStyle(.white)
                Text(detail).font(.system(size: 14)).foregroundStyle(.white.opacity(0.7))
            }
            HStack(spacing: 8) {
                Image(systemName: "play.fill").font(.system(size: 13, weight: .bold))
                Text("START").font(.system(size: 15, weight: .semibold)).tracking(1)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 48)
            .background(Theme.red, in: Capsule())
        }
        .padding(16)
        .background(Color(hex: 0x1B1D21), in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var sessionsCard: some View {
        Card {
            SectionLabel("Do a different session")
            NavigationLink { RunView(week: runWeek) } label: {
                TileRow(icon: "figure.run", title: "Run/walk intervals", subtitle: runWeek.title)
            }
            .buttonStyle(.plain)
            ForEach(GymPlan.days) { day in
                NavigationLink { GymView(day: day) } label: {
                    TileRow(icon: "dumbbell.fill", title: day.title,
                            subtitle: day.exercises.map(\.name).joined(separator: ", "))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
