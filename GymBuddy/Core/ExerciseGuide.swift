import CoreGraphics
import Foundation

/// How to perform an exercise: what it works, how to set up, the movement itself, and what to avoid.
struct ExerciseGuide {
    let muscles: String
    let setup: [String]
    let steps: [String]
    let mistakes: [String]
    let animation: ExerciseAnimation
}

enum ExerciseGuides {
    /// Guides are matched to `Exercise.name`.
    static func guide(for exerciseName: String) -> ExerciseGuide? {
        all[exerciseName]
    }

    private static let all: [String: ExerciseGuide] = [
        "Back squat": backSquat,
        "Bench press": benchPress,
        "Barbell row": barbellRow,
        "Plank": plank,
        "Romanian deadlift": romanianDeadlift,
        "Overhead press": overheadPress,
        "Lat pulldown": latPulldown,
        "Hanging knee raise": hangingKneeRaise,
        "Leg press": legPress,
        "Incline dumbbell press": inclineDumbbellPress,
        "Seated cable row": seatedCableRow,
        "Cable crunch": cableCrunch,
    ]

    // MARK: Full body A

    private static let backSquat = ExerciseGuide(
        muscles: "Quads, glutes, adductors, core and lower back.",
        setup: [
            "Set the bar in the rack at about mid-chest height. Set the safety arms just below the bottom of your squat.",
            "Step under the bar so it rests across your upper back, on the muscle shelf below your neck. Grip it just outside your shoulders.",
            "Stand up to lift it off, take two small steps back, and set your feet about shoulder-width apart with your toes turned out slightly.",
        ],
        steps: [
            "Take a big breath into your belly and brace your core as if about to be punched.",
            "Push your hips back and bend your knees at the same time, letting them track over your toes.",
            "Lower until your thighs are at least parallel to the floor, keeping your chest up and your back flat.",
            "Drive up through your whole foot, with your hips and chest rising together, and breathe out near the top.",
        ],
        mistakes: [
            "Knees caving inward. Push them out in line with your toes.",
            "Heels lifting off the floor. Keep your weight over the middle of your foot.",
            "Lower back rounding at the bottom. Stop at the depth where you can stay flat.",
            "Hips shooting up before your chest. Lead with your chest and hips together.",
        ],
        animation: ExerciseAnimation(
            start: FigurePose(torso: 90, thigh: -90, shin: -90, upperArm: -110, forearm: 60),
            end: FigurePose(torso: 50, head: 62, thigh: -5, shin: -115, upperArm: -105, forearm: 55),
            pin: .ankle,
            pinPoint: CGPoint(x: 0.6, y: 0.88),
            scale: 0.95,
            props: [
                .floor(y: 0.92),
                .plate(at: .shoulder, radius: 0.06),
            ],
            toEndLabel: "Sit back and down",
            toStartLabel: "Drive up, stand tall"
        )
    )

    private static let benchPress = ExerciseGuide(
        muscles: "Chest, front of the shoulders and triceps.",
        setup: [
            "Lie back with your eyes under the bar and your feet flat on the floor.",
            "Pinch your shoulder blades together and down, keeping a slight arch in your lower back, and keep your backside on the bench.",
            "Grip the bar a little wider than your shoulders, so your forearms are vertical at the bottom. Lift it off and hold it over your shoulders with your arms locked.",
        ],
        steps: [
            "Lower the bar under control to the middle of your chest, with your elbows about 45 to 60 degrees from your body.",
            "Touch your chest lightly without bouncing.",
            "Press the bar back up and slightly toward your face until your arms are straight over your shoulders.",
        ],
        mistakes: [
            "Bouncing the bar off your chest. Pause lightly instead.",
            "Flaring your elbows out to 90 degrees, which strains the shoulders.",
            "Lifting your backside off the bench.",
            "Bending your wrists back. Keep the bar over your forearms.",
            "Lifting heavy without a spotter or safety arms.",
        ],
        animation: ExerciseAnimation(
            start: FigurePose(torso: 180, thigh: 20, shin: -100, upperArm: 90, forearm: 90),
            end: FigurePose(torso: 180, thigh: 20, shin: -100, upperArm: -20, forearm: 90),
            pin: .hip,
            pinPoint: CGPoint(x: 0.66, y: 0.62),
            props: [
                .floor(y: 0.80),
                .pad(CGRect(x: 0.22, y: 0.66, width: 0.56, height: 0.035)),
                .segment(from: CGPoint(x: 0.28, y: 0.695), to: CGPoint(x: 0.28, y: 0.80), width: 0.02),
                .segment(from: CGPoint(x: 0.72, y: 0.695), to: CGPoint(x: 0.72, y: 0.80), width: 0.02),
                .plate(at: .wrist, radius: 0.055),
            ],
            toEndLabel: "Lower to mid-chest",
            toStartLabel: "Press up, arms locked"
        )
    )

    private static let barbellRow = ExerciseGuide(
        muscles: "Upper and middle back, lats, rear shoulders and biceps.",
        setup: [
            "Stand with your feet hip-width apart and the bar over the middle of your feet.",
            "Hinge forward at your hips with your knees slightly bent, until your torso is about 30 to 45 degrees above parallel with the floor.",
            "Grip the bar just outside your knees, overhand, and lift it so your arms hang straight down with a flat back.",
        ],
        steps: [
            "Brace your core and keep your back flat and your neck in line with your spine.",
            "Pull the bar to your lower ribs, driving your elbows back along your sides.",
            "Squeeze your shoulder blades together at the top for a moment.",
            "Lower the bar slowly until your arms are straight again.",
        ],
        mistakes: [
            "Jerking the weight up with momentum. Keep your torso still.",
            "Rounding your lower back. Lighten the weight until it stays flat.",
            "Standing up as you pull. Hold the same torso angle for the whole set.",
            "Pulling to your chest, which turns it into a shrug.",
        ],
        animation: ExerciseAnimation(
            start: FigurePose(torso: 35, head: 48, thigh: -40, shin: -110, upperArm: -100, forearm: -100),
            end: FigurePose(torso: 35, head: 48, thigh: -40, shin: -110, upperArm: 150, forearm: -85),
            pin: .ankle,
            pinPoint: CGPoint(x: 0.5, y: 0.88),
            scale: 0.95,
            props: [
                .floor(y: 0.92),
                .plate(at: .wrist, radius: 0.055),
            ],
            toEndLabel: "Pull elbows to hips",
            toStartLabel: "Lower, arms long"
        )
    )

    private static let plank = ExerciseGuide(
        muscles: "Abs, deep core, glutes and shoulders.",
        setup: [
            "Lie face down, then prop yourself up on your forearms with your elbows directly under your shoulders.",
            "Set your feet about hip-width apart and rise onto your toes.",
        ],
        steps: [
            "Make one straight line from your head to your heels.",
            "Squeeze your glutes and abs, and pull your ribs down toward your hips.",
            "Look at the floor just ahead of your hands so your neck stays neutral.",
            "Breathe steadily and hold for the target time.",
        ],
        mistakes: [
            "Hips sagging toward the floor, which loads your lower back.",
            "Hips piking up into the air.",
            "Shrugging your shoulders up toward your ears. Push the floor away.",
            "Holding your breath. Keep breathing slowly.",
            "Pushing on after your form breaks. End the set when it does.",
        ],
        animation: ExerciseAnimation(
            start: FigurePose(torso: 12, thigh: 192, shin: 192, upperArm: -90, forearm: 0, foot: -80),
            end: FigurePose(torso: 16, thigh: 196, shin: 196, upperArm: -90, forearm: 0, foot: -80),
            pin: .elbow,
            pinPoint: CGPoint(x: 0.98, y: 0.86),
            scale: 0.9,
            props: [
                .floor(y: 0.90),
            ],
            toEndLabel: "Brace and breathe",
            toStartLabel: "Straight line, head to heels",
            duration: 4.4
        )
    )

    // MARK: Full body B

    private static let romanianDeadlift = ExerciseGuide(
        muscles: "Hamstrings, glutes and lower back, with the core holding you steady.",
        setup: [
            "Stand with your feet hip-width apart, holding the bar in front of your thighs with an overhand grip just outside your legs.",
            "Soften your knees slightly and keep them that way for the whole set.",
        ],
        steps: [
            "Push your hips straight back, as if closing a car door with your backside.",
            "Keep the bar close, sliding it down your thighs, with your back flat and your chest proud.",
            "Lower until you feel a strong stretch in your hamstrings, usually around mid-shin.",
            "Squeeze your glutes and drive your hips forward to stand tall.",
        ],
        mistakes: [
            "Rounding your back. Stop lowering before it rounds.",
            "Bending your knees into a squat instead of hinging at the hips.",
            "Letting the bar drift away from your legs.",
            "Leaning back at the top. Finish standing tall, not arched.",
        ],
        animation: ExerciseAnimation(
            start: FigurePose(torso: 90, thigh: -90, shin: -90, upperArm: -85, forearm: -88),
            end: FigurePose(torso: 30, head: 40, thigh: -56, shin: -97, upperArm: -115, forearm: -105),
            pin: .ankle,
            pinPoint: CGPoint(x: 0.6, y: 0.88),
            scale: 0.95,
            props: [
                .floor(y: 0.92),
                .plate(at: .wrist, radius: 0.055),
            ],
            toEndLabel: "Hips back, bar down legs",
            toStartLabel: "Squeeze glutes, stand tall"
        )
    )

    private static let overheadPress = ExerciseGuide(
        muscles: "Shoulders, triceps and upper chest, with the core and glutes bracing.",
        setup: [
            "Rest the bar on your upper chest and front shoulders, with your grip just outside your shoulders.",
            "Stand with your feet hip-width apart and your elbows slightly in front of the bar.",
            "Squeeze your glutes and abs so your body is a solid column.",
        ],
        steps: [
            "Press the bar straight up, tucking your chin back slightly so it clears your face.",
            "Push your head forward through your arms once the bar passes your forehead.",
            "Lock out with the bar over the middle of your feet and your arms by your ears.",
            "Lower the bar back to your upper chest under control.",
        ],
        mistakes: [
            "Leaning back and arching your lower back. Keep your ribs down.",
            "Flaring your elbows far out to the sides.",
            "Pressing the bar out in front of you instead of straight up.",
            "Pushing with your legs. This is a strict press.",
        ],
        animation: ExerciseAnimation(
            start: FigurePose(torso: 90, thigh: -90, shin: -90, upperArm: 88, forearm: 90),
            end: FigurePose(torso: 90, thigh: -90, shin: -90, upperArm: -75, forearm: 90),
            pin: .ankle,
            pinPoint: CGPoint(x: 0.6, y: 0.88),
            scale: 0.78,
            props: [
                .floor(y: 0.92),
                .plate(at: .wrist, radius: 0.055),
            ],
            toEndLabel: "Lower to shoulders",
            toStartLabel: "Press straight up"
        )
    )

    private static let latPulldown = ExerciseGuide(
        muscles: "Lats, upper back and biceps.",
        setup: [
            "Adjust the thigh pad so it holds you down snugly.",
            "Take a wide overhand grip, about one and a half times shoulder-width.",
            "Sit tall with a slight lean back and your chest up.",
        ],
        steps: [
            "Start with your arms long and your shoulder blades lifted.",
            "Pull your shoulder blades down first, then drive your elbows down toward your ribs.",
            "Bring the bar to your upper chest and squeeze.",
            "Let the bar rise slowly until your arms are straight again.",
        ],
        mistakes: [
            "Leaning far back and yanking the bar with momentum.",
            "Pulling the bar behind your neck.",
            "Shrugging your shoulders up toward your ears.",
            "Pulling with your hands instead of leading with your elbows.",
        ],
        animation: ExerciseAnimation(
            start: FigurePose(torso: 98, thigh: 5, shin: -90, upperArm: 80, forearm: 82),
            end: FigurePose(torso: 98, thigh: 5, shin: -90, upperArm: -100, forearm: 55),
            pin: .hip,
            pinPoint: CGPoint(x: 0.55, y: 0.68),
            scale: 0.9,
            props: [
                .floor(y: 0.91),
                .pad(CGRect(x: 0.38, y: 0.70, width: 0.30, height: 0.03)),
                .segment(from: CGPoint(x: 0.52, y: 0.73), to: CGPoint(x: 0.52, y: 0.91), width: 0.02),
                .pad(CGRect(x: 0.60, y: 0.612, width: 0.16, height: 0.03)),
                .cable(from: CGPoint(x: 0.56, y: 0.03), to: .wrist),
                .plate(at: .wrist, radius: 0.022, gear: .wideBar),
            ],
            toEndLabel: "Elbows down to ribs",
            toStartLabel: "Arms long, chest up"
        )
    )

    private static let hangingKneeRaise = ExerciseGuide(
        muscles: "Abs, with the hip flexors and grip helping.",
        setup: [
            "Hang from a pull-up bar with an overhand grip about shoulder-width apart.",
            "Pull your shoulders slightly down away from your ears and keep your legs together.",
        ],
        steps: [
            "Brace your abs and keep your body still.",
            "Raise your knees toward your chest.",
            "At the top, curl your pelvis up and tilt it back. That curl is what works your abs.",
            "Lower your legs slowly without swinging.",
        ],
        mistakes: [
            "Swinging for momentum. Pause at the bottom to settle.",
            "Only lifting your thighs without curling your pelvis.",
            "Dropping your legs fast on the way down.",
            "Shrugging your shoulders up by your ears.",
        ],
        animation: ExerciseAnimation(
            start: FigurePose(torso: 90, thigh: -90, shin: -90, upperArm: 90, forearm: 90, foot: -60),
            end: FigurePose(torso: 105, thigh: 25, shin: -105, upperArm: 90, forearm: 90, foot: -60),
            pin: .wrist,
            pinPoint: CGPoint(x: 0.6, y: 0.10),
            scale: 0.7,
            props: [
                .floor(y: 0.92),
                .segment(from: CGPoint(x: 0.95, y: 0.10), to: CGPoint(x: 0.95, y: 0.92), width: 0.02),
                .segment(from: CGPoint(x: 0.6, y: 0.10), to: CGPoint(x: 0.95, y: 0.10), width: 0.016),
                .plate(at: .wrist, radius: 0.02, gear: .wideBar),
            ],
            toEndLabel: "Curl knees up",
            toStartLabel: "Lower slowly"
        )
    )

    // MARK: Full body C

    private static let legPress = ExerciseGuide(
        muscles: "Quads and glutes, with the hamstrings and calves helping.",
        setup: [
            "Sit with your back and hips flat against the pad.",
            "Place your feet about shoulder-width apart in the middle of the platform, with your toes turned out slightly.",
            "Release the safety handles and hold the side grips.",
        ],
        steps: [
            "Lower the platform until your knees are bent to about 90 degrees, or as deep as you can go with your hips staying on the seat.",
            "Press through your whole foot, keeping your knees in line with your toes.",
            "Stop just short of locking your knees.",
            "Lower again under control.",
        ],
        mistakes: [
            "Your hips lifting off the seat at the bottom. Go less deep.",
            "Locking your knees hard at the top, which puts stress on the joint.",
            "Knees collapsing inward.",
            "Using too much weight for tiny half reps.",
            "Pushing on your knees with your hands.",
        ],
        animation: ExerciseAnimation(
            start: FigurePose(torso: 125, head: 115, thigh: 83, shin: -5, upperArm: -40, forearm: -100, foot: 85),
            end: FigurePose(torso: 125, head: 115, thigh: 44, shin: 38, upperArm: -40, forearm: -100, foot: 128),
            pin: .hip,
            pinPoint: CGPoint(x: 0.36, y: 0.64),
            scale: 0.9,
            props: [
                .floor(y: 0.91),
                .segment(from: CGPoint(x: 0.343, y: 0.646), to: CGPoint(x: 0.15, y: 0.37), width: 0.035),
                .segment(from: CGPoint(x: 0.30, y: 0.665), to: CGPoint(x: 0.42, y: 0.665), width: 0.03),
                .segment(from: CGPoint(x: 0.48, y: 0.74), to: CGPoint(x: 1.0, y: 0.22), width: 0.014),
                .slab(at: .ankle, angle: 135, length: 0.26, shift: 0.035),
            ],
            toEndLabel: "Press, don't lock knees",
            toStartLabel: "Lower to about 90°"
        )
    )

    private static let inclineDumbbellPress = ExerciseGuide(
        muscles: "Upper chest, front of the shoulders and triceps.",
        setup: [
            "Set the bench to a low incline, around 30 degrees.",
            "Sit with the dumbbells on your thighs, then lie back and kick them up one at a time.",
            "Pinch your shoulder blades together and keep your feet flat on the floor.",
        ],
        steps: [
            "Lower the dumbbells to the sides of your upper chest, with your elbows about 45 to 60 degrees from your body.",
            "Press them up and slightly together until your arms are straight over your shoulders.",
            "Lower them again with control, without letting them clank together.",
        ],
        mistakes: [
            "A bench set too steep, which turns it into a shoulder press.",
            "Flaring your elbows out wide.",
            "One side rising faster than the other. Keep both even.",
            "Dropping the dumbbells quickly at the bottom.",
        ],
        animation: ExerciseAnimation(
            start: FigurePose(torso: 135, thigh: 10, shin: -85, upperArm: 95, forearm: 90),
            end: FigurePose(torso: 135, thigh: 10, shin: -85, upperArm: -50, forearm: 90),
            pin: .hip,
            pinPoint: CGPoint(x: 0.58, y: 0.65),
            scale: 0.9,
            props: [
                .floor(y: 0.86),
                .segment(from: CGPoint(x: 0.545, y: 0.685), to: CGPoint(x: 0.262, y: 0.402), width: 0.035),
                .segment(from: CGPoint(x: 0.545, y: 0.685), to: CGPoint(x: 0.70, y: 0.685), width: 0.035),
                .segment(from: CGPoint(x: 0.62, y: 0.70), to: CGPoint(x: 0.62, y: 0.86), width: 0.02),
                .segment(from: CGPoint(x: 0.40, y: 0.56), to: CGPoint(x: 0.40, y: 0.86), width: 0.02),
                .plate(at: .wrist, radius: 0.035, gear: .dumbbell),
            ],
            toEndLabel: "Lower to upper chest",
            toStartLabel: "Press up over shoulders"
        )
    )

    private static let seatedCableRow = ExerciseGuide(
        muscles: "Middle back, lats, rear shoulders and biceps.",
        setup: [
            "Sit with your feet on the platform and your knees slightly bent.",
            "Reach forward and take the handle with your arms straight, then sit tall with your chest up.",
        ],
        steps: [
            "Keep your torso upright and your back flat.",
            "Pull the handle to your lower ribs, drawing your elbows back past your sides.",
            "Squeeze your shoulder blades together and pause.",
            "Let your arms extend slowly, letting your shoulders stretch forward a little while your back stays flat.",
        ],
        mistakes: [
            "Rocking your torso back and forth to move the weight.",
            "Shrugging your shoulders up.",
            "Rounding your back as you reach forward.",
            "Pulling with only your arms instead of your back.",
        ],
        animation: ExerciseAnimation(
            start: FigurePose(torso: 80, thigh: 12, shin: -8, upperArm: 5, forearm: 3, foot: 85),
            end: FigurePose(torso: 95, thigh: 12, shin: -8, upperArm: 210, forearm: 10, foot: 85),
            pin: .hip,
            pinPoint: CGPoint(x: 0.36, y: 0.66),
            scale: 0.9,
            props: [
                .floor(y: 0.80),
                .pad(CGRect(x: 0.26, y: 0.69, width: 0.20, height: 0.03)),
                .segment(from: CGPoint(x: 0.36, y: 0.72), to: CGPoint(x: 0.36, y: 0.80), width: 0.02),
                .segment(from: CGPoint(x: 0.84, y: 0.55), to: CGPoint(x: 0.84, y: 0.80), width: 0.02),
                .cable(from: CGPoint(x: 1.18, y: 0.46), to: .wrist),
                .plate(at: .wrist, radius: 0.02, gear: .handle),
            ],
            toEndLabel: "Pull handle to belly",
            toStartLabel: "Reach forward, back flat"
        )
    )

    private static let cableCrunch = ExerciseGuide(
        muscles: "Abs (rectus abdominis), with the obliques helping.",
        setup: [
            "Attach a rope to a high pulley and kneel facing the machine, a little back from it.",
            "Hold the rope beside your head with your elbows pointing down.",
            "Set your hips over your knees. They should stay there for the whole set.",
        ],
        steps: [
            "Breathe out and curl your ribs toward your hips, rounding your spine and bringing your elbows toward your thighs.",
            "Keep your hips still. Only your spine moves.",
            "Squeeze your abs at the bottom for a moment.",
            "Return slowly, resisting the weight on the way up.",
        ],
        mistakes: [
            "Sitting your hips back toward your heels, which makes it a hip hinge instead.",
            "Pulling with your arms. They only hold the rope in place.",
            "Using so much weight that you swing.",
            "Folding forward without curling your spine.",
        ],
        animation: ExerciseAnimation(
            start: FigurePose(torso: 78, thigh: -90, shin: 180, upperArm: -30, forearm: 100, foot: 180),
            end: FigurePose(torso: 60, curl: 80, head: -30, thigh: -90, shin: 180, upperArm: -60, forearm: 110, foot: 180),
            pin: .knee,
            pinPoint: CGPoint(x: 0.55, y: 0.86),
            scale: 0.95,
            props: [
                .floor(y: 0.90),
                .cable(from: CGPoint(x: 0.5, y: 0.02), to: .wrist),
            ],
            toEndLabel: "Curl ribs toward hips",
            toStartLabel: "Return slowly"
        )
    )
}
