import Foundation

enum Sex: String, Codable, CaseIterable, Identifiable {
    case male, female, unspecified
    var id: String { rawValue }
}

enum FitnessLevel: String, Codable, CaseIterable, Identifiable {
    case beginner, intermediate, advanced
    var id: String { rawValue }
    var progressionWeeks: Int {
        switch self {
        case .beginner: return 4
        case .intermediate: return 6
        case .advanced: return 8
        }
    }
    var intensityFactor: Double {
        switch self {
        case .beginner: return 0.7
        case .intermediate: return 0.9
        case .advanced: return 1.15
        }
    }

    /// The level reached after completing this one's full cycle, or `nil`
    /// once already at `advanced` (nothing further to level up to).
    var next: FitnessLevel? {
        switch self {
        case .beginner: return .intermediate
        case .intermediate: return .advanced
        case .advanced: return nil
        }
    }
}

enum Goal: String, Codable, CaseIterable, Identifiable {
    case fatLoss, strengthMass, militaryEndurance, mobility
    var id: String { rawValue }
}

enum Equipment: String, Codable, CaseIterable, Identifiable {
    case bodyweightOnly, pullUpBar, parallettes
    var id: String { rawValue }
}

enum AgeBand {
    case under30, thirty40, over40

    init(age: Int) {
        if age < 30 { self = .under30 }
        else if age <= 40 { self = .thirty40 }
        else { self = .over40 }
    }
}

struct UserProfile: Codable, Equatable {
    var weightKg: Double
    var heightCm: Double
    var age: Int
    var sex: Sex
    var level: FitnessLevel
    var goal: Goal
    var daysPerWeek: Int
    var equipment: Equipment
    var sessionMinutes: Int

    static let empty = UserProfile(
        weightKg: 75, heightCm: 175, age: 28, sex: .unspecified,
        level: .beginner, goal: .fatLoss, daysPerWeek: 4, equipment: .bodyweightOnly,
        sessionMinutes: 30
    )

    var bmi: Double {
        let heightM = heightCm / 100
        guard heightM > 0 else { return 0 }
        return weightKg / (heightM * heightM)
    }

    var ageBand: AgeBand { AgeBand(age: age) }

    var isValid: Bool {
        (30...250).contains(weightKg) &&
        (120...230).contains(heightCm) &&
        (14...75).contains(age) &&
        (3...6).contains(daysPerWeek) &&
        (15...60).contains(sessionMinutes)
    }
}

enum BlockKind: String, Codable {
    case warmup, strength, circuit, core, cooldown
}

struct PlannedExercise: Codable, Identifiable, Equatable {
    var id: String { name }
    let name: String
    let sets: Int
    let reps: Int?
    let seconds: Int?
    let restSeconds: Int
}

struct WorkoutBlock: Codable, Identifiable, Equatable {
    var id: String { kind.rawValue }
    let kind: BlockKind
    let exercises: [PlannedExercise]
}

struct DailyWorkout: Codable, Identifiable, Equatable {
    var id: String { dayLabel }
    let dayLabel: String
    let blocks: [WorkoutBlock]
}

struct WeekPlan: Codable, Identifiable, Equatable {
    var id: Int { index }
    let index: Int
    let isDeload: Bool
    let days: [DailyWorkout]
}

struct WeeklyPlan: Codable, Equatable {
    let weeks: [WeekPlan]
    let generatedFor: UserProfile
}
