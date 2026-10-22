import Foundation

enum Nutrition {
    /// Mifflin-St Jeor resting energy for a man, in kcal/day.
    static func restingCalories(weightKg: Double, heightCm: Double, age: Int) -> Double {
        10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
    }

    /// Maintenance for 6 training sessions a week (3 gym + 3 runs): activity factor 1.55.
    static func maintenanceCalories(weightKg: Double, heightCm: Double, age: Int) -> Int {
        roundedTo5(restingCalories(weightKg: weightKg, heightCm: heightCm, age: age) * 1.55)
    }

    /// A moderate cut of about 0.4 kg per week, which keeps muscle while losing fat.
    static func cutCalories(weightKg: Double, heightCm: Double, age: Int) -> Int {
        maintenanceCalories(weightKg: weightKg, heightCm: heightCm, age: age) - 500
    }

    static func proteinGrams(weightKg: Double) -> Int {
        Int((weightKg * 1.8 / 5).rounded()) * 5
    }

    private static func roundedTo5(_ value: Double) -> Int {
        Int((value / 5).rounded()) * 5
    }

    /// US Navy body fat estimate for men, from waist and neck circumference (cm). Accurate to a few percent at best.
    static func navyBodyFat(waistCm: Double, neckCm: Double, heightCm: Double) -> Double? {
        guard waistCm > neckCm else { return nil }
        return 86.010 * log10(waistCm - neckCm) - 70.041 * log10(heightCm) + 36.76
    }
}
