import SwiftUI

/// A looping 3D demo of an exercise with a caption for the current phase of the movement.
/// With Reduce Motion on, it shows the start and end positions instead, switched by a control.
struct ExerciseDemoView: View {
    let animation: ExerciseAnimation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingEnd = false

    var body: some View {
        VStack(spacing: 12) {
            Figure3DView(animation: animation, fixedProgress: reduceMotion ? (showingEnd ? 1 : 0) : nil)

            if reduceMotion {
                Picker("Position", selection: $showingEnd) {
                    Text("Start").tag(false)
                    Text("Finish").tag(true)
                }
                .pickerStyle(.segmented)
                caption(showingEnd ? animation.toEndLabel : animation.toStartLabel)
            } else {
                // The figure animates itself; this only keeps the caption in step with it.
                TimelineView(.periodic(from: .now, by: 0.1)) { timeline in
                    caption(animation.playback(at: timeline.date).movingToEnd ? animation.toEndLabel : animation.toStartLabel)
                }
            }
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
    }
}
