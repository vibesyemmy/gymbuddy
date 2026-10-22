import Combine
import SwiftData
import SwiftUI
import UIKit

private struct SetEntry: Identifiable {
    let id = UUID()
    var weight: Double
    var reps: Int
    var done = false
}

private struct ExerciseRow: Identifiable {
    let exercise: Exercise
    var hint: String
    var sets: [SetEntry]
    var id: String { exercise.id }
}

struct GymView: View {
    let day: GymDay
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \GymLog.date, order: .reverse) private var history: [GymLog]
    @State private var rows: [ExerciseRow] = []
    @State private var restRemaining = 0
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        List {
            Section {
                Text("Warm up 5 minutes (easy walk or bike), then do a lighter first set of each lift. Stop each set with about 2 reps left in the tank.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            ForEach($rows) { $row in
                Section {
                    ForEach($row.sets) { $entry in
                        setRow(row.exercise, index: row.sets.firstIndex { $0.id == entry.id } ?? 0, entry: $entry)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(row.exercise.name) · \(row.exercise.target) \(row.exercise.unit)")
                            .font(.headline).textCase(nil).foregroundStyle(.primary)
                        Text(row.hint).font(.caption).textCase(nil)
                    }
                }
            }
        }
        .navigationTitle(day.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Finish", action: finish).disabled(!rows.contains { $0.sets.contains(where: \.done) })
            }
        }
        .safeAreaInset(edge: .bottom) {
            if restRemaining > 0 {
                HStack {
                    Text("Rest \(Format.clock(Double(restRemaining)))").font(.title3.bold().monospacedDigit())
                    Spacer()
                    Button("Skip") { restRemaining = 0 }
                }
                .padding()
                .background(.regularMaterial)
            }
        }
        .onAppear(perform: buildRows)
        .onReceive(ticker) { _ in
            guard restRemaining > 0 else { return }
            restRemaining -= 1
            if restRemaining == 0 { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        }
    }

    private func setRow(_ exercise: Exercise, index: Int, entry: Binding<SetEntry>) -> some View {
        HStack {
            Text("Set \(index + 1)").frame(width: 50, alignment: .leading)
            if !exercise.isBodyweight {
                TextField("kg", value: entry.weight, format: .number)
                    .keyboardType(.decimalPad).textFieldStyle(.roundedBorder).frame(width: 80)
                Text("kg").foregroundStyle(.secondary)
            }
            TextField(exercise.unit, value: entry.reps, format: .number)
                .keyboardType(.numberPad).textFieldStyle(.roundedBorder).frame(width: 70)
            Text(exercise.unit).foregroundStyle(.secondary)
            Spacer()
            Button {
                entry.wrappedValue.done.toggle()
                if entry.wrappedValue.done { restRemaining = exercise.restSeconds }
            } label: {
                Image(systemName: entry.wrappedValue.done ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(entry.wrappedValue.done ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Data

    private func lastSets(for name: String) -> [SetLog]? {
        history.lazy.compactMap { log -> [SetLog]? in
            let sets = log.sets.filter { $0.exercise == name }
            return sets.isEmpty ? nil : sets.sorted { $0.setNumber < $1.setNumber }
        }.first
    }

    private func buildRows() {
        guard rows.isEmpty else { return }
        rows = day.exercises.map { exercise in
            var weight = 0.0
            var reps = exercise.repsLow
            var hint = "First time: start light and focus on clean form."
            if let last = lastSets(for: exercise.name) {
                let top = last.map(\.weightKg).max() ?? 0
                let hitAll = last.count >= exercise.sets && last.allSatisfy { $0.reps >= exercise.repsHigh }
                let summary = last.map { exercise.isBodyweight ? "\($0.reps)" : "\(Format.kg($0.weightKg))×\($0.reps)" }.joined(separator: ", ")
                if exercise.isBodyweight {
                    reps = last.map(\.reps).max() ?? reps
                    hint = hitAll ? "Last: \(summary). Hit the top of the range, so add reps or time." : "Last: \(summary). Beat it."
                } else if hitAll {
                    weight = top + exercise.increment
                    hint = "Last: \(summary). All reps hit, so go up to \(Format.kg(weight)) kg."
                } else {
                    weight = top
                    hint = "Last: \(summary). Stay at \(Format.kg(top)) kg until every set hits \(exercise.repsHigh)."
                }
            }
            return ExerciseRow(exercise: exercise, hint: hint,
                               sets: (0..<exercise.sets).map { _ in SetEntry(weight: weight, reps: reps) })
        }
    }

    private func finish() {
        let log = GymLog(date: .now, dayKey: day.key, title: day.title)
        context.insert(log)
        for row in rows {
            for (index, entry) in row.sets.enumerated() where entry.done {
                log.sets.append(SetLog(exercise: row.exercise.name, setNumber: index + 1, weightKg: entry.weight, reps: entry.reps))
            }
        }
        dismiss()
    }
}
