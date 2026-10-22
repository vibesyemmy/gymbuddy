import CoreGraphics
import Foundation

// A side-on stick figure facing right, posed by joint angles (so limb lengths never change while it
// animates). Angles are degrees counter-clockwise from "right": 0 = right, 90 = up, 180 = left,
// -90 = down. Each angle runs from a segment's upper joint to its lower joint (hip to knee, etc.).

enum FigureJoint {
    case hip, shoulder, head, knee, ankle, elbow, wrist
}

struct FigurePose {
    var torso: Double      // hip to shoulder
    var curl: Double       // extra forward bend of the upper half of the torso (spine flexion)
    var head: Double       // shoulder to head
    var thigh: Double      // hip to knee
    var shin: Double       // knee to ankle
    var upperArm: Double   // shoulder to elbow
    var forearm: Double    // elbow to wrist
    var foot: Double       // ankle to toes; 0 is flat on the floor. Only the 3D figure draws feet.

    /// `head` defaults to continuing the line of the spine.
    init(torso: Double, curl: Double = 0, head: Double? = nil, thigh: Double, shin: Double, upperArm: Double, forearm: Double, foot: Double = 0) {
        self.torso = torso
        self.curl = curl
        self.head = head ?? torso - curl
        self.thigh = thigh
        self.shin = shin
        self.upperArm = upperArm
        self.forearm = forearm
        self.foot = foot
    }

    func blended(to other: FigurePose, _ t: Double) -> FigurePose {
        func mix(_ a: Double, _ b: Double) -> Double { a + (b - a) * t }
        return FigurePose(
            torso: mix(torso, other.torso),
            curl: mix(curl, other.curl),
            head: mix(head, other.head),
            thigh: mix(thigh, other.thigh),
            shin: mix(shin, other.shin),
            upperArm: mix(upperArm, other.upperArm),
            forearm: mix(forearm, other.forearm),
            foot: mix(foot, other.foot)
        )
    }
}

struct FigureJoints {
    var hip: CGPoint
    /// Midpoint of the torso, where it bends when the spine curls.
    var spine: CGPoint
    var shoulder: CGPoint
    var head: CGPoint
    var knee: CGPoint
    var ankle: CGPoint
    var elbow: CGPoint
    var wrist: CGPoint

    func point(_ joint: FigureJoint) -> CGPoint {
        switch joint {
        case .hip: hip
        case .shoulder: shoulder
        case .head: head
        case .knee: knee
        case .ankle: ankle
        case .elbow: elbow
        case .wrist: wrist
        }
    }

    func mapped(_ transform: (CGPoint) -> CGPoint) -> FigureJoints {
        FigureJoints(
            hip: transform(hip), spine: transform(spine), shoulder: transform(shoulder), head: transform(head),
            knee: transform(knee), ankle: transform(ankle), elbow: transform(elbow), wrist: transform(wrist)
        )
    }

    /// Scales the figure, flips it to screen orientation (y down) and slides it so `pin` sits at `target`.
    func placed(scale: Double, pin: FigureJoint, at target: CGPoint) -> FigureJoints {
        let flipped = mapped { CGPoint(x: $0.x * scale, y: -$0.y * scale) }
        let anchor = flipped.point(pin)
        return flipped.mapped { CGPoint(x: $0.x - anchor.x + target.x, y: $0.y - anchor.y + target.y) }
    }
}

enum FigureGeometry {
    /// The drawing space is `canvasAspect` wide and 1 tall, with y pointing down.
    static let canvasAspect = 1.25

    static let torsoLength = 0.26
    static let thighLength = 0.23
    static let shinLength = 0.23
    static let upperArmLength = 0.15
    static let forearmLength = 0.14
    static let neckLength = 0.075
    static let headRadius = 0.05

    /// Joint positions with the hip at the origin and y pointing up.
    static func joints(for pose: FigurePose) -> FigureJoints {
        let hip = CGPoint.zero
        let spine = hip.moved(pose.torso, torsoLength / 2)
        let shoulder = spine.moved(pose.torso - pose.curl, torsoLength / 2)
        let knee = hip.moved(pose.thigh, thighLength)
        let elbow = shoulder.moved(pose.upperArm, upperArmLength)
        return FigureJoints(
            hip: hip,
            spine: spine,
            shoulder: shoulder,
            head: shoulder.moved(pose.head, neckLength),
            knee: knee,
            ankle: knee.moved(pose.shin, shinLength),
            elbow: elbow,
            wrist: elbow.moved(pose.forearm, forearmLength)
        )
    }
}

private extension CGPoint {
    func moved(_ degrees: Double, _ length: Double) -> CGPoint {
        let radians = degrees * .pi / 180
        return CGPoint(x: x + cos(radians) * length, y: y + sin(radians) * length)
    }
}

/// What a `plate` prop is in 3D. The 2D figure draws all of them as a circle.
enum FigureGear {
    case barbell    // a long bar with plates on the ends
    case dumbbell   // one in each hand
    case wideBar    // a long bar without plates: lat pulldown bar, pull-up bar
    case handle     // a shorter cable attachment
}

/// Equipment drawn around the figure. Points and rectangles are in drawing space (y down).
enum FigureProp {
    case floor(y: Double)
    case segment(from: CGPoint, to: CGPoint, width: Double = 0.012)
    case pad(CGRect)
    /// A barbell, dumbbell or bar centred on a joint; seen end-on in 2D.
    case plate(at: FigureJoint, radius: Double, gear: FigureGear = .barbell)
    /// A cable from a fixed point to a joint.
    case cable(from: CGPoint, to: FigureJoint)
    /// A flat surface through a joint, such as a leg press platform. `angle` is the direction of the
    /// surface in degrees (as for poses) and `shift` moves it along its normal.
    case slab(at: FigureJoint, angle: Double, length: Double, shift: Double)
}

/// One looping demo: the figure moves from `start` to `end` and back.
struct ExerciseAnimation {
    var start: FigurePose
    var end: FigurePose
    /// The joint that stays put on screen while the rest of the figure moves, and where it sits.
    var pin: FigureJoint
    var pinPoint: CGPoint
    var scale: Double = 1
    var props: [FigureProp]
    /// Caption shown while moving to the end pose and while returning to the start.
    var toEndLabel: String
    var toStartLabel: String
    var duration: Double = 3.6

    /// Where the loop is at `date`: eased progress from start (0) to end (1), and which way it is moving.
    func playback(at date: Date) -> (progress: Double, movingToEnd: Bool) {
        let cycle = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: duration) / duration
        let movingToEnd = cycle < 0.5
        let u = movingToEnd ? cycle * 2 : (1 - cycle) * 2
        // Ease in and out, with a short pause at each end.
        let x = min(max((u - 0.12) / 0.76, 0), 1)
        return (x * x * (3 - 2 * x), movingToEnd)
    }
}
