import Foundation
import HealthKit

/// Reads past workouts of every type (runs, walks, rides, gym sessions…) from HealthKit,
/// whether they were recorded by the Fitness app, an Apple Watch or another app.
enum HealthImporter {
    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Distance types to ask for, so workouts of each kind report their distance.
    private static let distanceTypes: Set<HKQuantityType> = [
        HKQuantityType(.distanceWalkingRunning),
        HKQuantityType(.distanceCycling),
        HKQuantityType(.distanceSwimming),
        HKQuantityType(.distanceWheelchair),
        HKQuantityType(.distanceDownhillSnowSports),
    ]

    /// Asks for read access, then returns the workouts in Health since `start` (all of them when nil), newest first.
    /// HealthKit never reveals whether read access was denied, so a denial looks like an empty result.
    static func fetch(since start: Date?) async throws -> [ImportedRun] {
        let store = HKHealthStore()
        var readTypes = Set<HKObjectType>()
        readTypes.insert(HKObjectType.workoutType())
        for type in distanceTypes { readTypes.insert(type) }
        try await store.requestAuthorization(toShare: [], read: readTypes)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(HKQuery.predicateForSamples(withStart: start, end: nil, options: []))],
            sortDescriptors: [SortDescriptor(\HKWorkout.startDate, order: .reverse)]
        )
        let workouts = try await descriptor.result(for: store)

        return workouts.compactMap { workout in
            // Skip workouts with no recorded time.
            guard workout.duration > 0 else { return nil }
            // A workout normally has one kind of distance; take the largest so nothing is counted twice.
            let meters = workout.allStatistics
                .filter { $0.key.is(compatibleWith: .meter()) }
                .compactMap { $0.value.sumQuantity()?.doubleValue(for: .meter()) }
                .max() ?? 0
            return ImportedRun(
                sourceID: workout.uuid.uuidString,
                activity: label(for: workout.workoutActivityType),
                date: workout.startDate,
                distanceMeters: meters,
                duration: workout.duration
            )
        }
    }

    private static func label(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: "Run"
        case .walking: "Walk"
        case .hiking: "Hike"
        case .cycling: "Ride"
        case .swimming: "Swim"
        case .traditionalStrengthTraining, .functionalStrengthTraining: "Strength"
        case .highIntensityIntervalTraining: "HIIT"
        case .yoga: "Yoga"
        case .pilates: "Pilates"
        case .coreTraining: "Core"
        case .elliptical: "Elliptical"
        case .rowing: "Row"
        case .stairClimbing: "Stairs"
        default: "Workout"
        }
    }
}
