import SwiftUI

/// Small "Form" pill that opens an exercise's guide.
struct FormButton: View {
    let exerciseName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Form", systemImage: "play.circle.fill")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Theme.tile, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("How to do \(exerciseName)")
    }
}

/// Animated demo plus written instructions for one gym exercise.
struct ExerciseGuideView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ThemedScroll {
                if let guide = ExerciseGuides.guide(for: exercise.name) {
                    Card { ExerciseDemoView(animation: guide.animation) }

                    Card {
                        SectionLabel("Your target")
                        Text("\(exercise.target) \(exercise.unit) · rest \(exercise.restSeconds)s")
                            .font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                        Text(guide.muscles)
                            .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                    }

                    stepsCard("Setup", guide.setup, numbered: true)
                    stepsCard("How to do it", guide.steps, numbered: true)
                    stepsCard("Common mistakes", guide.mistakes, numbered: false)

                    Text("Start light and learn the movement before adding weight. If something hurts (as opposed to feeling hard), stop and ask a coach.")
                        .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                } else {
                    Card {
                        Text("There's no form guide for this exercise yet.")
                            .font(.system(size: 15)).foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func stepsCard(_ title: String, _ items: [String], numbered: Bool) -> some View {
        Card {
            SectionLabel(title)
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 12) {
                    if numbered {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                            .frame(width: 22, height: 22)
                            .background(Theme.tile, in: Circle())
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13)).foregroundStyle(Theme.amber)
                            .frame(width: 22, height: 22)
                    }
                    Text(item)
                        .font(.system(size: 15)).foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
