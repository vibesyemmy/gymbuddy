import SceneKit
import SwiftUI

/// The 3D mannequin demo. Drag to turn it, or use the Side, 3/4 and Front buttons.
struct Figure3DView: View {
    /// While nil the figure loops; otherwise it holds this point of the movement (0 = start, 1 = end).
    var fixedProgress: Double?

    @State private var figure: FigureScene
    @State private var yaw = FigureScene.defaultYaw
    @State private var dragStartYaw: Float?

    init(animation: ExerciseAnimation, fixedProgress: Double? = nil) {
        self.fixedProgress = fixedProgress
        _figure = State(initialValue: FigureScene(animation: animation))
    }

    var body: some View {
        VStack(spacing: 10) {
            SceneView(
                scene: figure.scene,
                pointOfView: figure.camera,
                options: [.rendersContinuously],
                preferredFramesPerSecond: 60,
                antialiasingMode: .multisampling4X,
                delegate: figure
            )
            .aspectRatio(FigureGeometry.canvasAspect, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Theme.tileRadius))
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        let start = dragStartYaw ?? yaw
                        dragStartYaw = start
                        yaw = start + Float(value.translation.width) * 0.012
                        figure.setYaw(yaw, animated: false)
                    }
                    .onEnded { _ in dragStartYaw = nil }
            )
            // The caption and the written steps describe the movement, so the 3D view adds nothing for VoiceOver.
            .accessibilityHidden(true)

            HStack(spacing: 8) {
                viewButton("Side", yaw: 0)
                viewButton("3/4", yaw: FigureScene.defaultYaw)
                viewButton("Front", yaw: -.pi / 2)
            }
            Text("Drag to turn the figure")
                .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
        }
        .onAppear { figure.fixedProgress = fixedProgress }
        .onChange(of: fixedProgress) { _, newValue in figure.fixedProgress = newValue }
    }

    private func viewButton(_ title: String, yaw target: Float) -> some View {
        let isSelected = abs(yaw - target) < 0.05
        return Button {
            yaw = target
            figure.setYaw(target, animated: true)
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : Theme.textPrimary)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(isSelected ? Theme.red : Theme.tile, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) view")
    }
}
