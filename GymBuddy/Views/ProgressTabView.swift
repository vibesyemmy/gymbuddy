import Charts
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ProgressTabView: View {
    @AppStorage("heightCm") fileprivate var heightCm: Double = 182.9
    @AppStorage("age") fileprivate var age: Int = 40
    @Query(sort: \BodyEntry.date) fileprivate var entries: [BodyEntry]
    @Query(sort: \RunLog.date, order: .reverse) fileprivate var runs: [RunLog]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false
    @State fileprivate var isImporting = false
    @State fileprivate var importMessage: String?
    @State fileprivate var showingStravaPicker = false
    @AppStorage("importPeriod") fileprivate var importPeriod: ImportPeriod = .all

    fileprivate var latest: BodyEntry? { entries.last }
    fileprivate var waistEntries: [BodyEntry] { entries.filter { $0.waistCm != nil } }

    /// Saves activities not already in the log and returns a status message. Imported activities
    /// aren't part of the plan, so they get week 0 and no route.
    private func save(_ imported: [ImportedRun], emptyMessage: String) -> String {
        let fresh = ImportedRun.newRuns(imported, existing: runs)
        for run in fresh {
            context.insert(RunLog(
                date: run.date,
                week: 0,
                distanceMeters: run.distanceMeters,
                duration: run.duration,
                routeLat: [],
                routeLon: [],
                sourceID: run.sourceID,
                activity: run.activity
            ))
        }
        if imported.isEmpty { return emptyMessage }
        guard !fresh.isEmpty else { return "Already up to date." }

        // e.g. "Imported 12 activities: 8 Walk, 3 Run, 1 Strength."
        let counts = Dictionary(grouping: fresh, by: \.activity).map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
        let breakdown = counts.map { "\($0.1) \($0.0)" }.joined(separator: ", ")
        return "Imported \(fresh.count) \(fresh.count == 1 ? "activity" : "activities"): \(breakdown)."
    }

    fileprivate func importFromHealth() async {
        isImporting = true
        defer { isImporting = false }
        do {
            let found = try await HealthImporter.fetch(since: importPeriod.startDate)
            importMessage = save(found, emptyMessage: "No workouts found for this period. If you expected some, check GymBuddy's access in Settings → Privacy & Security → Health.")
        } catch {
            importMessage = "Couldn't read Health: \(error.localizedDescription)"
        }
    }

    private func importFromStrava(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            // Files picked outside the app sandbox need security-scoped access to be read.
            guard url.startAccessingSecurityScopedResource() else {
                importMessage = "Couldn't open that file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            let text = String(decoding: try Data(contentsOf: url), as: UTF8.self)
            let start = importPeriod.startDate
            let stravaRuns = try StravaImporter.runs(fromCSV: text).filter { run in start.map { run.date >= $0 } ?? true }
            importMessage = save(stravaRuns, emptyMessage: "No activities found in that file for this period.")
        } catch {
            importMessage = "Couldn't import from Strava: \(error.localizedDescription)"
        }
    }

    var body: some View {
        NavigationStack {
            ThemedScroll {
                bodyCard
                if entries.count > 1 {
                    chartCard("Weight (kg)", entries: entries, value: \.weightKg, unit: "kg")
                }
                if waistEntries.count > 1 {
                    chartCard("Waist (cm)", entries: waistEntries, value: { $0.waistCm ?? 0 }, unit: "cm")
                }
                activitiesCard
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Add entry", systemImage: "plus") { showingAdd = true }
                    .tint(Theme.red)
            }
            .fileImporter(isPresented: $showingStravaPicker, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
                importFromStrava(result)
            }
            .sheet(isPresented: $showingAdd) {
                AddEntrySheet(lastWeight: latest?.weightKg ?? 83.6)
                    .presentationDetents([.medium])
            }
        }
    }
}

extension ProgressTabView {
    fileprivate var bodyCard: some View {
        Card {
            SectionLabel("Body")
            if let latest {
                VStack(spacing: 0) {
                    StatRow(label: "Weight", value: "\(Format.kg(latest.weightKg)) kg")
                    if let waist = latest.waistCm {
                        StatRow(label: "Waist", value: "\(Format.kg(waist)) cm")
                        StatRow(label: "Waist ÷ height", value: String(format: "%.2f", waist / heightCm))
                        if let neck = latest.neckCm,
                           let bodyFat = Nutrition.navyBodyFat(waistCm: waist, neckCm: neck, heightCm: heightCm) {
                            StatRow(label: "Body fat (estimate)", value: String(format: "%.1f%%", bodyFat))
                        }
                    }
                    StatRow(label: "Daily calories (fat loss)", value: "\(Nutrition.cutCalories(weightKg: latest.weightKg, heightCm: heightCm, age: age)) kcal")
                    StatRow(label: "Maintenance", value: "\(Nutrition.maintenanceCalories(weightKg: latest.weightKg, heightCm: heightCm, age: age)) kcal")
                    StatRow(label: "Daily protein target", value: "\(Nutrition.proteinGrams(weightKg: latest.weightKg)) g", showsDivider: false)
                }
            } else {
                Text("Add your first entry to start tracking.")
                    .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
            }
            Text("Abs show through when waist ÷ height is roughly 0.45 or lower. Measure your waist at the navel (relaxed, not sucked in) and your neck just below the larynx, once a week at the same time. Body fat from tape measures is an estimate; watch the trend, not the number.")
                .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
        }
    }

    fileprivate func chartCard(_ title: String, entries: [BodyEntry], value: @escaping (BodyEntry) -> Double, unit: String) -> some View {
        Card {
            SectionLabel(title)
            Chart(entries) { entry in
                LineMark(x: .value("Date", entry.date), y: .value(unit, value(entry)))
                    .foregroundStyle(Theme.red)
                    .interpolationMethod(.monotone)
                PointMark(x: .value("Date", entry.date), y: .value(unit, value(entry)))
                    .foregroundStyle(Theme.red)
                    .symbolSize(30)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 180)
        }
    }

    fileprivate var activitiesCard: some View {
        Card {
            SectionLabel("Activities")
            VStack(spacing: 0) {
                StatRow(label: "Run & walk distance", value: "\(Format.km(runs.filter(\.isRunOrWalk).reduce(0) { $0 + $1.distanceMeters })) km")
                StatRow(label: "Activities logged", value: "\(runs.count)", showsDivider: !runs.isEmpty)
                ForEach(Array(runs.prefix(5).enumerated()), id: \.element.persistentModelID) { index, run in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(run.activity ?? "Run") · \(run.date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 15)).foregroundStyle(Theme.textPrimary)
                        Text(run.summary).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                    if index < min(runs.count, 5) - 1 { Divider().overlay(Theme.divider) }
                }
            }
            Picker("Import period", selection: $importPeriod) {
                ForEach(ImportPeriod.allCases) { period in
                    Text(period.title).tag(period)
                }
            }
            .tint(Theme.textPrimary)
            Button { Task { await importFromHealth() } } label: {
                TileRow(icon: "heart.text.square", title: isImporting ? "Importing…" : "Import past activities from Health", chevron: "arrow.down.circle")
            }
            .buttonStyle(.plain)
            .disabled(isImporting || !HealthImporter.isAvailable)
            Button { showingStravaPicker = true } label: {
                TileRow(icon: "square.and.arrow.down", title: "Import from Strava export", subtitle: "activities.csv", chevron: "arrow.down.circle")
            }
            .buttonStyle(.plain)
            if let importMessage {
                Text(importMessage).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

private struct AddEntrySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var weightText: String
    @State private var waistText = ""
    @State private var neckText = ""

    init(lastWeight: Double) {
        _weightText = State(initialValue: String(format: "%.1f", lastWeight))
    }

    private func parse(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Weight (kg)", text: $weightText).keyboardType(.decimalPad)
                TextField("Waist at navel (cm), optional", text: $waistText).keyboardType(.decimalPad)
                TextField("Neck (cm), optional, for body fat", text: $neckText).keyboardType(.decimalPad)
            }
            .navigationTitle("New entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let weight = parse(weightText) {
                            context.insert(BodyEntry(weightKg: weight, waistCm: parse(waistText), neckCm: parse(neckText)))
                            dismiss()
                        }
                    }
                    .disabled(parse(weightText) == nil)
                }
            }
        }
    }
}
