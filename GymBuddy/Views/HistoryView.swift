import SwiftData
import SwiftUI

/// Everything logged so far (runs, walks, other activities and gym sessions), filterable by period.
struct HistoryView: View {
    @Query(sort: \RunLog.date, order: .reverse) private var runs: [RunLog]
    @Query(sort: \GymLog.date, order: .reverse) private var gymLogs: [GymLog]
    @State private var period: HistoryPeriod = .thisMonth

    private enum Entry: Identifiable {
        case activity(RunLog)
        case gym(GymLog)

        var id: PersistentIdentifier {
            switch self {
            case .activity(let run): run.persistentModelID
            case .gym(let log): log.persistentModelID
            }
        }

        var date: Date {
            switch self {
            case .activity(let run): run.date
            case .gym(let log): log.date
            }
        }
    }

    private var periodRuns: [RunLog] {
        guard let start = period.startDate else { return runs }
        return runs.filter { $0.date >= start }
    }

    private var periodGymLogs: [GymLog] {
        guard let start = period.startDate else { return gymLogs }
        return gymLogs.filter { $0.date >= start }
    }

    private var entries: [Entry] {
        (periodRuns.map(Entry.activity) + periodGymLogs.map(Entry.gym)).sorted { $0.date > $1.date }
    }

    /// Entries grouped by calendar month, newest month first; order within a month is preserved.
    private var months: [(month: Date, entries: [Entry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { calendar.dateInterval(of: .month, for: $0.date)?.start ?? $0.date }
        return grouped.map { (month: $0.key, entries: $0.value) }.sorted { $0.month > $1.month }
    }

    /// Per-activity counts and distance, most frequent first.
    private var breakdown: [(activity: String, count: Int, meters: Double)] {
        Dictionary(grouping: periodRuns) { $0.activity ?? "Run" }
            .map { (activity: $0.key, count: $0.value.count, meters: $0.value.reduce(0) { $0 + $1.distanceMeters }) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        NavigationStack {
            ThemedScroll {
                periodPicker

                if entries.isEmpty {
                    Card {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar").font(.system(size: 28)).foregroundStyle(Theme.textSecondary)
                            Text("Nothing in this period").font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                            Text("Try a longer period.").font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                } else {
                    summaryCard
                    if !breakdown.isEmpty { breakdownCard }
                    ForEach(months, id: \.month) { group in
                        Card(padding: 0) {
                            SectionLabel(group.month.formatted(.dateTime.month(.wide).year()))
                                .padding(.horizontal, 16).padding(.top, 16)
                            VStack(spacing: 0) {
                                ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                                    row(for: entry)
                                    if index < group.entries.count - 1 { Divider().overlay(Theme.divider) }
                                }
                            }
                            .padding(.horizontal, 16).padding(.bottom, 4)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Sections

    private var periodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HistoryPeriod.allCases) { option in
                    Button { period = option } label: {
                        Text(option.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(period == option ? .white : Theme.textPrimary)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(period == option ? Color(hex: 0x4A5568) : Theme.card, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var summaryCard: some View {
        Card {
            SectionLabel("Summary")
            HStack(spacing: 8) {
                StatTile(label: "Activities", value: "\(periodRuns.count)")
                StatTile(label: "Gym sessions", value: "\(periodGymLogs.count)")
            }
            HStack(spacing: 8) {
                StatTile(label: "Run & walk", value: Format.km(periodRuns.filter(\.isRunOrWalk).reduce(0) { $0 + $1.distanceMeters }), unit: "km")
                StatTile(label: "Time active", value: Format.clock(periodRuns.reduce(0) { $0 + $1.duration }))
            }
        }
    }

    private var breakdownCard: some View {
        Card {
            SectionLabel("By activity")
            VStack(spacing: 0) {
                ForEach(Array(breakdown.enumerated()), id: \.element.activity) { index, item in
                    StatRow(label: item.activity,
                            value: item.meters > 0 ? "\(item.count) · \(Format.km(item.meters)) km" : "\(item.count)",
                            showsDivider: index < breakdown.count - 1)
                }
            }
        }
    }

    @ViewBuilder
    private func row(for entry: Entry) -> some View {
        switch entry {
        case .activity(let run):
            row(icon: Self.icon(for: run.activity), title: run.activity ?? "Run", detail: run.summary, date: run.date)
        case .gym(let log):
            let exercises = Set(log.sets.map(\.exercise)).count
            row(icon: "dumbbell.fill", title: log.title, detail: "\(log.sets.count) sets · \(exercises) exercises", date: log.date)
        }
    }

    private func row(icon: String, title: String, detail: String, date: Date) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 40, height: 40)
                .background(Theme.tile, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .medium)).foregroundStyle(Theme.textPrimary)
                Text(detail).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 12)
    }

    private static func icon(for activity: String?) -> String {
        switch activity {
        case nil, "Run": "figure.run"
        case "Walk": "figure.walk"
        case "Hike": "figure.hiking"
        case "Ride": "figure.outdoor.cycle"
        case "Swim": "figure.pool.swim"
        case "Strength": "dumbbell.fill"
        case "Yoga": "figure.yoga"
        case "HIIT": "figure.highintensity.intervaltraining"
        default: "figure.mixed.cardio"
        }
    }
}
