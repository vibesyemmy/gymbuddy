import Charts
import SwiftData
import SwiftUI

struct ProgressTabView: View {
    @AppStorage("heightCm") private var heightCm: Double = 182.9
    @Query(sort: \BodyEntry.date) private var entries: [BodyEntry]
    @Query(sort: \RunLog.date, order: .reverse) private var runs: [RunLog]
    @State private var showingAdd = false

    private var latest: BodyEntry? { entries.last }
    private var waistEntries: [BodyEntry] { entries.filter { $0.waistCm != nil } }

    var body: some View {
        NavigationStack {
            List {
                Section("Body") {
                    if let latest {
                        LabeledContent("Weight", value: "\(Format.kg(latest.weightKg)) kg")
                        if let waist = latest.waistCm {
                            LabeledContent("Waist", value: "\(Format.kg(waist)) cm")
                            LabeledContent("Waist ÷ height", value: String(format: "%.2f", waist / heightCm))
                        }
                        LabeledContent("Daily protein target", value: "\(Int((latest.weightKg * 1.8 / 5).rounded()) * 5) g")
                    } else {
                        Text("Add your first entry to start tracking.").foregroundStyle(.secondary)
                    }
                    Text("Abs show through when waist ÷ height is roughly 0.45 or lower. Measure your waist at the navel, relaxed, every week at the same time.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                if entries.count > 1 {
                    Section("Weight (kg)") {
                        Chart(entries) { entry in
                            LineMark(x: .value("Date", entry.date), y: .value("kg", entry.weightKg))
                            PointMark(x: .value("Date", entry.date), y: .value("kg", entry.weightKg))
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .frame(height: 180)
                    }
                }
                if waistEntries.count > 1 {
                    Section("Waist (cm)") {
                        Chart(waistEntries) { entry in
                            LineMark(x: .value("Date", entry.date), y: .value("cm", entry.waistCm ?? 0))
                            PointMark(x: .value("Date", entry.date), y: .value("cm", entry.waistCm ?? 0))
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .frame(height: 180)
                    }
                }

                Section("Running") {
                    LabeledContent("Total distance", value: "\(Format.km(runs.reduce(0) { $0 + $1.distanceMeters })) km")
                    LabeledContent("Runs logged", value: "\(runs.count)")
                    ForEach(runs.prefix(5)) { run in
                        VStack(alignment: .leading) {
                            Text(run.date.formatted(date: .abbreviated, time: .shortened))
                            Text("\(Format.km(run.distanceMeters)) km · \(Format.clock(run.duration)) · \(Format.pace(distance: run.distanceMeters, duration: run.duration)) /km")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Progress")
            .toolbar {
                Button("Add entry", systemImage: "plus") { showingAdd = true }
            }
            .sheet(isPresented: $showingAdd) {
                AddEntrySheet(lastWeight: latest?.weightKg ?? 83.6)
                    .presentationDetents([.medium])
            }
        }
    }
}

private struct AddEntrySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var weightText: String
    @State private var waistText = ""

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
            }
            .navigationTitle("New entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let weight = parse(weightText) {
                            context.insert(BodyEntry(weightKg: weight, waistCm: parse(waistText)))
                            dismiss()
                        }
                    }
                    .disabled(parse(weightText) == nil)
                }
            }
        }
    }
}
