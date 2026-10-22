import XCTest
@testable import GymBuddy

final class IntervalEngineTests: XCTestCase {
    private let run = Segment(phase: .run, duration: 60)
    private let walk = Segment(phase: .walk, duration: 120)

    func testAdvancesThroughSegments() {
        var engine = IntervalEngine(segments: [run, walk])
        XCTAssertEqual(engine.start(), [.started(run)])
        XCTAssertEqual(engine.advance(by: 59), [])
        XCTAssertEqual(engine.remainingInSegment, 1, accuracy: 0.001)
        XCTAssertEqual(engine.advance(by: 1), [.started(walk)])
        XCTAssertEqual(engine.advance(by: 120), [.finished])
        XCTAssertTrue(engine.isFinished)
    }

    func testLargeStepCrossesSeveralSegments() {
        var engine = IntervalEngine(segments: [run, walk, run])
        _ = engine.start()
        XCTAssertEqual(engine.advance(by: 200), [.started(walk), .started(run)])
        XCTAssertEqual(engine.remainingInSegment, 40, accuracy: 0.001)
    }

    func testEmptyEngineIsFinished() {
        var engine = IntervalEngine(segments: [])
        XCTAssertEqual(engine.start(), [.finished])
        XCTAssertTrue(engine.isFinished)
    }

    func testEveryPlanWeekIsWellFormed() {
        var previousRunTime = 0
        for week in RunPlan.weeks {
            let segments = week.segments
            XCTAssertEqual(segments.first?.phase, .warmup)
            XCTAssertEqual(segments.last?.phase, .cooldown)
            let runTime = segments.filter { $0.phase == .run }.reduce(0) { $0 + Int($1.duration) }
            XCTAssertGreaterThan(runTime, previousRunTime, "Week \(week.number) should run more than the week before")
            previousRunTime = runTime
        }
        XCTAssertEqual(RunPlan.week(99).number, RunPlan.weeks.count)
        XCTAssertEqual(RunPlan.week(0).number, 1)
    }

    func testSchedule() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        func date(_ day: Int) -> Date { calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: 12))! }
        XCTAssertEqual(Schedule.session(on: date(19), calendar: calendar), .gym)   // Monday
        XCTAssertEqual(Schedule.session(on: date(20), calendar: calendar), .run)   // Tuesday
        XCTAssertEqual(Schedule.session(on: date(25), calendar: calendar), .rest)  // Sunday
        XCTAssertEqual(Schedule.programWeek(start: date(19), now: date(19), calendar: calendar), 1)
        XCTAssertEqual(Schedule.programWeek(start: date(19), now: date(26), calendar: calendar), 2)
    }

    func testNutritionForA40YearOldMan() {
        XCTAssertEqual(Nutrition.restingCalories(weightKg: 83.6, heightCm: 182.9, age: 40), 1784.1, accuracy: 0.1)
        XCTAssertEqual(Nutrition.maintenanceCalories(weightKg: 83.6, heightCm: 182.9, age: 40), 2765)
        XCTAssertEqual(Nutrition.cutCalories(weightKg: 83.6, heightCm: 182.9, age: 40), 2265)
        XCTAssertEqual(Nutrition.proteinGrams(weightKg: 83.6), 150)
    }

    func testNavyBodyFat() throws {
        let bodyFat = try XCTUnwrap(Nutrition.navyBodyFat(waistCm: 95, neckCm: 38, heightCm: 182.9))
        XCTAssertEqual(bodyFat, 29.3, accuracy: 0.2)
        XCTAssertNil(Nutrition.navyBodyFat(waistCm: 35, neckCm: 38, heightCm: 182.9))
    }
}
