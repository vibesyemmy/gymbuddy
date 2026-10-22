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
    @State private var elapsed = 0
    @State private var guideExercise: Exercise?
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var completedBlocks: Int {
        rows.filter { !$0.sets.isEmpty && $0.sets.allSatisfy(\.done) }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryHeader
                Text("Warm up 5 minutes (easy walk or bike), then do a lighter first set of each lift. Stop each set with about 2 reps left in the tank.")
                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                ForEach($rows) { $row in
                    exerciseCard($row)
                }
            }
            .padding(16)
        }
        .background(Theme.page.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(day.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .preferredColorScheme(.dark)
        .sheet(item: $guideExercise) { ExerciseGuideView(exercise: $0) }
        .onAppear(perform: buildRows)
        .onReceive(ticker) { _ in
            elapsed += 1
            guard restRemaining > 0 else { return }
            restRemaining -= 1
            if restRemaining == 0 { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        }
    }

    // MARK: Sections

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Format.clock(Double(elapsed)))
                .font(.system(size: 56, weight: .light)).monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: 12) {
                Text("\(completedBlocks)/\(rows.count) Blocks")
                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                BlockProgress(completed: completedBlocks, total: rows.count)
            }
        }
    }

    private func exerciseCard(_ row: Binding<ExerciseRow>) -> some View {
        let exercise = row.wrappedValue.exercise
        return Card {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name).font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                    Text("\(exercise.target) \(exercise.unit) · rest \(exercise.restSeconds)s")
                        .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if ExerciseGuides.guide(for: exercise.name) != nil {
                    FormButton(exerciseName: exercise.name) { guideExercise = exercise }
                }
            }
            Text(row.wrappedValue.hint)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Theme.tile, in: Capsule())
            ForEach(row.sets) { $entry in
                setRow(exercise, index: row.wrappedValue.sets.firstIndex { $0.id == entry.id } ?? 0, entry: $entry)
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if restRemaining > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionLabel("Rest")
                        Text(Format.clock(Double(restRemaining)))
                            .font(.system(size: 28, weight: .light)).monospacedDigit()
                            .foregroundStyle(Theme.mint)
                    }
                    Spacer()
                    Button("Skip") { restRemaining = 0 }
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Theme.tile, in: Capsule())
                }
            }
            PrimaryButton(title: "Finish workout", icon: "checkmark", action: finish)
                .disabled(!rows.contains { $0.sets.contains(where: \.done) })
                .opacity(rows.contains { $0.sets.contains(where: \.done) } ? 1 : 0.4)
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func setRow(_ exercise: Exercise, index: Int, entry: Binding<SetEntry>) -> some View {
        HStack(spacing: 8) {
            Text("Set \(index + 1)")
                .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                .frame(width: 44, alignment: .leading)
            if !exercise.isBodyweight {
                TextField("kg", value: entry.weight, format: .number)
                    .keyboardType(.decimalPad).setField(width: 72)
                Text("kg").font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
            }
            TextField(exercise.unit, value: entry.reps, format: .number)
                .keyboardType(.numberPad).setField(width: 64)
            Text(exercise.unit).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
            Spacer()
            Button {
                entry.wrappedValue.done.toggle()
                if entry.wrappedValue.done { restRemaining = exercise.restSeconds }
            } label: {
                Image(systemName: entry.wrappedValue.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundStyle(entry.wrappedValue.done ? Theme.mint : Theme.textSecondary.opacity(0.6))
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

private extension View {
    func setField(width: CGFloat) -> some View {
        multilineTextAlignment(.center)
            .font(.system(size: 17, weight: .medium)).monospacedDigit()
            .frame(width: width, height: 40)
            .background(Theme.tile, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
    }
}
