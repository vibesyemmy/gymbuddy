import SwiftUI

/// The full list of exercises for a gym day, each with its target and a Form guide, plus a Start button.
struct GymDetailView: View {
    let day: GymDay
    let onStart: () -> Void
    @State private var guideExercise: Exercise?

    var body: some View {
        ThemedScroll {
            Card {
                SectionLabel("Gym")
                Text(day.title).font(.system(size: 24, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text("\(day.exercises.count) exercises · about 45 min")
                    .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                Text("Warm up 5 minutes (easy walk or bike), then do a lighter first set of each lift. Stop each set with about 2 reps left in the tank.")
                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.tile, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
            }

            Card {
                SectionLabel("Your session")
                ForEach(Array(day.exercises.enumerated()), id: \.element.id) { index, exercise in
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                                .frame(width: 22, height: 22)
                                .background(Theme.tile, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.system(size: 16, weight: .medium)).foregroundStyle(Theme.textPrimary)
                                Text("\(exercise.target) \(exercise.unit) · rest \(exercise.restSeconds)s")
                                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            if ExerciseGuides.guide(for: exercise.name) != nil {
                                FormButton(exerciseName: exercise.name) { guideExercise = exercise }
                            }
                        }
                        .padding(.vertical, 10)
                        if index < day.exercises.count - 1 { Divider().overlay(Theme.divider) }
                    }
                }
            }
        }
        .navigationTitle(day.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryButton(title: "Start workout", icon: "play.fill", action: onStart)
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
                .background(.ultraThinMaterial)
        }
        .sheet(item: $guideExercise) { ExerciseGuideView(exercise: $0) }
    }
}
