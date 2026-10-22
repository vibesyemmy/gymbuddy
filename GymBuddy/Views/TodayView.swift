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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Week \(week) of your plan")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    todayCard

                    VStack(alignment: .leading, spacing: 8) {
                        Text("This week").font(.headline)
                        HStack {
                            stat("Gym", "\(gymLogs.filter { isThisWeek($0.date) }.count) / 3")
                            stat("Runs", "\(runLogs.filter { isThisWeek($0.date) }.count) / 3")
                            stat("Run km", Format.km(runLogs.filter { isThisWeek($0.date) }.reduce(0) { $0 + $1.distanceMeters }))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Do a different session").font(.headline)
                        NavigationLink { RunView(week: runWeek) } label: {
                            row(icon: "figure.run", title: "Run/walk intervals", subtitle: runWeek.title)
                        }
                        ForEach(GymPlan.days) { day in
                            NavigationLink { GymView(day: day) } label: {
                                row(icon: "dumbbell.fill", title: day.title, subtitle: day.exercises.map(\.name).joined(separator: ", "))
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
        }
    }

    @ViewBuilder
    private var todayCard: some View {
        switch Schedule.session(on: .now) {
        case .gym:
            NavigationLink { GymView(day: nextGymDay) } label: {
                card(icon: "dumbbell.fill", title: nextGymDay.title, subtitle: "Gym day · about 45 min", tint: .orange)
            }
        case .run:
            NavigationLink { RunView(week: runWeek) } label: {
                card(icon: "figure.run", title: "Week \(runWeek.number) run", subtitle: "\(runWeek.title) · \(runWeek.totalMinutes) min", tint: .green)
            }
        case .rest:
            card(icon: "bed.double.fill", title: "Rest day", subtitle: "Easy walk if you feel like it. Recovery is when you grow.", tint: .indigo)
        }
    }

    private func card(icon: String, title: String, subtitle: String, tint: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.largeTitle)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title2.bold())
                Text(subtitle).font(.subheadline)
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding()
        .background(tint.gradient, in: RoundedRectangle(cornerRadius: 16))
    }

    private func row(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).frame(width: 28)
            VStack(alignment: .leading) {
                Text(title).font(.body.weight(.medium))
                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(.primary)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack {
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
    }
}
