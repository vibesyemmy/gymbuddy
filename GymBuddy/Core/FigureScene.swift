import CoreGraphics
import Foundation
import SceneKit
import simd

/// A 3D mannequin and its equipment for an `ExerciseAnimation`. It uses the same poses and equipment
/// positions as the 2D figure, with both arms and legs and real bars, benches and cables.
///
/// The figure faces +x in the scene, and a camera on +z sees it from the side. `setYaw` turns the whole
/// stage, so the lights and camera stay put while the figure and its equipment rotate together.
final class FigureScene: NSObject, SCNSceneRendererDelegate {
    /// Side-on with a slight turn, so it reads as 3D straight away.
    static let defaultYaw: Float = -0.45

    let scene = SCNScene()
    let camera = SCNNode()
    private let stage = SCNNode()

    /// While nil the figure loops; otherwise it is held at this point between start (0) and end (1).
    var fixedProgress: Double?

    private let animation: ExerciseAnimation

    private struct Link {
        let node: SCNNode
        let ends: (FigureJoints, FigurePose) -> (SIMD3<Float>, SIMD3<Float>)
    }

    private var links: [Link] = []
    private var dots: [(node: SCNNode, at: (FigureJoints) -> SIMD3<Float>)] = []
    private var gear: [(root: SCNNode, joint: FigureJoint)] = []
    private var slabs: [(node: SCNNode, joint: FigureJoint, angle: Double, shift: Double)] = []
    private var cables: [(node: SCNNode, from: SIMD3<Float>, joint: FigureJoint)] = []

    init(animation: ExerciseAnimation) {
        self.animation = animation
        super.init()
        buildEnvironment()
        buildFigure()
        buildProps()
        setYaw(Self.defaultYaw, animated: false)
        apply(progress: 0)
    }

    // MARK: Control

    func setYaw(_ yaw: Float, animated: Bool) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = animated ? 0.35 : 0
        stage.simdEulerAngles.y = yaw
        SCNTransaction.commit()
    }

    /// Poses every part for a point between the start (0) and end (1) of the movement.
    func apply(progress: Double) {
        let pose = animation.start.blended(to: animation.end, progress)
        let joints = FigureGeometry.joints(for: pose)
            .placed(scale: animation.scale, pin: animation.pin, at: animation.pinPoint)

        for link in links {
            let (a, b) = link.ends(joints, pose)
            Self.place(link.node, from: a, to: b)
        }
        for dot in dots {
            dot.node.simdPosition = dot.at(joints)
        }
        for item in gear {
            item.root.simdPosition = Self.world(joints.point(item.joint))
        }
        for slab in slabs {
            let radians = slab.angle * .pi / 180
            // The surface runs along `angle`; its normal points the way the legs push.
            let normal = SIMD3<Float>(Float(sin(radians)), Float(-cos(radians)), 0)
            slab.node.simdPosition = Self.world(joints.point(slab.joint)) + normal * Float(slab.shift)
        }
        for cable in cables {
            Self.place(cable.node, from: cable.from, to: Self.world(joints.point(cable.joint)))
            if let cylinder = cable.node.geometry as? SCNCylinder {
                cylinder.height = CGFloat(simd_distance(cable.from, Self.world(joints.point(cable.joint))))
            }
        }
    }

    // MARK: SCNSceneRendererDelegate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        apply(progress: fixedProgress ?? animation.playback(at: Date()).progress)
    }

    // MARK: Building

    private func buildEnvironment() {
        scene.background.contents = CGColor(srgbRed: 0.102, green: 0.110, blue: 0.125, alpha: 1)
        scene.rootNode.addChildNode(stage)

        let lens = SCNCamera()
        lens.fieldOfView = 30
        lens.zNear = 0.1
        lens.zFar = 20
        camera.camera = lens
        camera.simdPosition = SIMD3(0, 0.15, 2.0)
        camera.simdEulerAngles = SIMD3(-0.075, 0, 0)
        scene.rootNode.addChildNode(camera)

        func light(_ type: SCNLight.LightType, intensity: CGFloat, angles: SIMD3<Float>? = nil, shadows: Bool = false) {
            let node = SCNNode()
            let light = SCNLight()
            light.type = type
            light.intensity = intensity
            light.color = CGColor(gray: 1, alpha: 1)
            if shadows {
                light.castsShadow = true
                light.shadowRadius = 3
                light.shadowSampleCount = 8
                light.shadowColor = CGColor(gray: 0, alpha: 0.55)
            }
            node.light = light
            if let angles { node.simdEulerAngles = angles }
            scene.rootNode.addChildNode(node)
        }
        light(.ambient, intensity: 480)
        light(.directional, intensity: 1100, angles: SIMD3(-0.9, -0.55, 0), shadows: true)
        light(.directional, intensity: 350, angles: SIMD3(-0.4, 0.9, 0))
    }

    private func buildFigure() {
        let s = Float(animation.scale)
        let skin = Self.material(0xD8C8BC)
        let joint = Self.material(0xC2B1A4)
        let legZ = 0.055 * s
        let armZ = 0.12 * s
        let scale = animation.scale

        func link(radius: Double, length: Double, widthScale: Float = 1, material: SCNMaterial,
                  ends: @escaping (FigureJoints, FigurePose) -> (SIMD3<Float>, SIMD3<Float>)) {
            let r = CGFloat(radius * scale)
            let capsule = SCNCapsule(capRadius: r, height: CGFloat(length * scale) + 2 * r)
            capsule.materials = [material]
            let node = SCNNode(geometry: capsule)
            node.simdScale = SIMD3(1, 1, widthScale)
            stage.addChildNode(node)
            links.append(Link(node: node, ends: ends))
        }

        func dot(radius: Double, scale dotScale: SIMD3<Float> = SIMD3(1, 1, 1), material: SCNMaterial,
                 at: @escaping (FigureJoints) -> SIMD3<Float>) {
            let sphere = SCNSphere(radius: CGFloat(radius * scale))
            sphere.materials = [material]
            let node = SCNNode(geometry: sphere)
            node.simdScale = dotScale
            stage.addChildNode(node)
            dots.append((node, at))
        }

        // Spine and pelvis.
        link(radius: 0.05, length: FigureGeometry.torsoLength / 2, widthScale: 1.55, material: skin) { j, _ in
            (Self.world(j.hip), Self.world(j.spine))
        }
        link(radius: 0.058, length: FigureGeometry.torsoLength / 2, widthScale: 1.85, material: skin) { j, _ in
            (Self.world(j.spine), Self.world(j.shoulder))
        }
        link(radius: 0.045, length: 0.11, material: skin) { j, _ in
            (Self.world(j.hip, z: -0.055 * s), Self.world(j.hip, z: 0.055 * s))
        }
        // Shoulder girdle, neck and head.
        link(radius: 0.036, length: 0.24, material: skin) { j, _ in
            (Self.world(j.shoulder, z: -armZ), Self.world(j.shoulder, z: armZ))
        }
        link(radius: 0.02, length: FigureGeometry.neckLength, material: skin) { j, _ in
            (Self.world(j.shoulder), Self.world(j.head))
        }
        dot(radius: 0.05, scale: SIMD3(0.95, 1.15, 0.95), material: skin) { Self.world($0.head) }

        // Both legs and both arms follow the same pose.
        for side: Float in [-1, 1] {
            let lz = legZ * side
            let az = armZ * side
            link(radius: 0.04, length: FigureGeometry.thighLength, material: skin) { j, _ in
                (Self.world(j.hip, z: lz), Self.world(j.knee, z: lz))
            }
            link(radius: 0.029, length: FigureGeometry.shinLength, material: skin) { j, _ in
                (Self.world(j.knee, z: lz), Self.world(j.ankle, z: lz))
            }
            link(radius: 0.02, length: 0.09, material: joint) { j, pose in
                let radians = pose.foot * .pi / 180
                let along = SIMD3<Float>(Float(cos(radians)), Float(sin(radians)), 0)
                let down = SIMD3<Float>(Float(sin(radians)), Float(-cos(radians)), 0)
                let ankle = Self.world(j.ankle, z: lz) + down * 0.018
                return (ankle - along * 0.025, ankle + along * 0.065)
            }
            link(radius: 0.028, length: FigureGeometry.upperArmLength, material: skin) { j, _ in
                (Self.world(j.shoulder, z: az), Self.world(j.elbow, z: az))
            }
            link(radius: 0.021, length: FigureGeometry.forearmLength, material: skin) { j, _ in
                (Self.world(j.elbow, z: az), Self.world(j.wrist, z: az))
            }
            dot(radius: 0.04, material: joint) { Self.world($0.shoulder, z: az) }
            dot(radius: 0.033, material: joint) { Self.world($0.knee, z: lz) }
            dot(radius: 0.026, material: joint) { Self.world($0.elbow, z: az) }
            dot(radius: 0.024, material: joint) { Self.world($0.wrist, z: az) }
        }
    }

    private func buildProps() {
        let equipment = Self.material(0x6B717B)
        let steel = Self.material(0xB8BDC6, shine: 0.5)
        let floor = Self.material(0x2B2E34)

        for prop in animation.props {
            switch prop {
            case .floor(let y):
                let top = Float(0.5 - y)
                // Big enough that its edges never come into view, whichever way the stage turns.
                let slab = SCNBox(width: 12, height: 0.03, length: 12, chamferRadius: 0)
                slab.materials = [floor]
                let node = SCNNode(geometry: slab)
                node.simdPosition = SIMD3(0, top - 0.015, 0)
                stage.addChildNode(node)

            case .segment(let from, let to, let width):
                let a = Self.world(from)
                let b = Self.world(to)
                if width >= 0.025 {
                    // Thick segments are flat pads, such as back rests and seats.
                    let box = SCNBox(width: CGFloat(simd_distance(a, b)), height: CGFloat(width), length: 0.3, chamferRadius: 0.008)
                    box.materials = [equipment]
                    let node = SCNNode(geometry: box)
                    node.simdPosition = (a + b) / 2
                    node.simdEulerAngles.z = atan2(b.y - a.y, b.x - a.x)
                    stage.addChildNode(node)
                } else {
                    let rod = SCNCylinder(radius: CGFloat(width / 2), height: CGFloat(simd_distance(a, b)))
                    rod.materials = [equipment]
                    let node = SCNNode(geometry: rod)
                    Self.place(node, from: a, to: b)
                    stage.addChildNode(node)
                }

            case .pad(let rect):
                let box = SCNBox(width: rect.width, height: rect.height, length: 0.3, chamferRadius: 0.008)
                box.materials = [equipment]
                let node = SCNNode(geometry: box)
                node.simdPosition = Self.world(CGPoint(x: rect.midX, y: rect.midY))
                stage.addChildNode(node)

            case .plate(let joint, let radius, let kind):
                let root = Self.gearNode(kind, plateRadius: CGFloat(radius), steel: steel, plate: Self.material(0xE0334F, shine: 0.3), armZ: 0.12 * Float(animation.scale))
                stage.addChildNode(root)
                gear.append((root, joint))

            case .cable(let from, let joint):
                let cylinder = SCNCylinder(radius: 0.004, height: 1)
                cylinder.materials = [equipment]
                let node = SCNNode(geometry: cylinder)
                stage.addChildNode(node)
                cables.append((node, Self.world(from), joint))

            case .slab(let joint, let angle, let length, let shift):
                let box = SCNBox(width: CGFloat(length), height: 0.025, length: 0.3, chamferRadius: 0.008)
                box.materials = [equipment]
                let node = SCNNode(geometry: box)
                node.simdEulerAngles.z = Float(angle * .pi / 180)
                stage.addChildNode(node)
                slabs.append((node, joint, angle, shift))
            }
        }
    }

    /// A barbell, dumbbells or bar centred on its joint, lying along the z axis.
    private static func gearNode(_ kind: FigureGear, plateRadius: CGFloat, steel: SCNMaterial, plate: SCNMaterial, armZ: Float) -> SCNNode {
        let root = SCNNode()

        /// A cylinder lying along z, centred at `z`.
        func part(radius: CGFloat, length: CGFloat, at z: Float, along: Float = 0, material: SCNMaterial) {
            let cylinder = SCNCylinder(radius: radius, height: length)
            cylinder.materials = [material]
            let node = SCNNode(geometry: cylinder)
            // A cylinder stands along y by default; turn it to lie along z.
            node.simdEulerAngles = SIMD3(Float.pi / 2, 0, 0)
            node.simdPosition = SIMD3(along, 0, z)
            root.addChildNode(node)
        }

        switch kind {
        case .barbell:
            part(radius: 0.01, length: 0.64, at: 0, material: steel)
            for side: Float in [-1, 1] {
                part(radius: plateRadius, length: 0.03, at: side * 0.24, material: plate)
                part(radius: plateRadius * 0.7, length: 0.03, at: side * 0.27, material: plate)
            }
        case .dumbbell:
            for side: Float in [-1, 1] {
                part(radius: 0.011, length: 0.1, at: side * armZ, material: steel)
                part(radius: plateRadius, length: 0.04, at: side * armZ - 0.06, material: plate)
                part(radius: plateRadius, length: 0.04, at: side * armZ + 0.06, material: plate)
            }
        case .wideBar:
            part(radius: 0.012, length: 0.7, at: 0, material: steel)
        case .handle:
            part(radius: 0.012, length: 0.3, at: 0, material: steel)
        }
        return root
    }

    // MARK: Helpers

    /// Drawing-space point (x right, y down, 0...1.25 by 0...1) to scene space (centred, y up).
    private static func world(_ point: CGPoint, z: Float = 0) -> SIMD3<Float> {
        SIMD3(Float(point.x - FigureGeometry.canvasAspect / 2), Float(0.5 - point.y), z)
    }

    /// Stands a node that is long along y between two points.
    private static func place(_ node: SCNNode, from a: SIMD3<Float>, to b: SIMD3<Float>) {
        let direction = b - a
        let length = simd_length(direction)
        guard length > 1e-5 else { return }
        node.simdPosition = (a + b) / 2
        node.simdOrientation = simd_quatf(from: SIMD3(0, 1, 0), to: direction / length)
    }

    private static func material(_ hex: UInt32, shine: CGFloat = 0.15) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .blinn
        material.diffuse.contents = CGColor(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
        material.specular.contents = CGColor(gray: 0.5, alpha: 1)
        material.shininess = shine
        return material
    }
}
