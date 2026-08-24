import Foundation

/// Generates a periodized weekly calisthenics plan from a user profile.
/// Mirrors the shared algorithm in docs/plan-engine-spec.md.
enum PlanEngine {

    static func generate(for profile: UserProfile) -> WeeklyPlan {
        let totalWeeks = profile.level.progressionWeeks
        let progressionStep = profile.ageBand == .over40 ? 0.025 : 0.05
        let intensity = intensityFactor(for: profile)

        let dayLabels = splitLabels(for: profile.daysPerWeek)

        var weeks: [WeekPlan] = []
        for w in 0..<totalWeeks {
            let isDeload = (w + 1) % 4 == 0
            let scale = isDeload ? 0.6 : 1 + progressionStep * Double(w)
            let days = dayLabels.enumerated().map { index, label in
                buildDay(label: label, splitIndex: index, profile: profile, intensity: intensity, scale: scale)
            }
            weeks.append(WeekPlan(index: w, isDeload: isDeload, days: days))
        }
        return WeeklyPlan(weeks: weeks, generatedFor: profile)
    }

    private static func intensityFactor(for profile: UserProfile) -> Double {
        var factor = profile.level.intensityFactor
        let bmi = profile.bmi
        if bmi > 27 { factor -= 0.1 }
        else if bmi < 18.5 { factor += 0.1 }
        if profile.ageBand == .over40 { factor *= 0.9 }
        return factor
    }

    private static func splitLabels(for daysPerWeek: Int) -> [String] {
        switch daysPerWeek {
        case 3: return ["day.fullBody1", "day.fullBody2", "day.fullBody3"]
        case 4: return ["day.upper", "day.lower", "day.fullBody", "day.conditioning"]
        case 5: return ["day.upper", "day.lower", "day.push", "day.pull", "day.conditioning"]
        default: return ["day.upper", "day.lower", "day.push", "day.pull", "day.conditioning", "day.mobility"]
        }
    }

    private static func buildDay(label: String, splitIndex: Int, profile: UserProfile, intensity: Double, scale: Double) -> DailyWorkout {
        let warmupBlock = block(.warmup, from: ExerciseCatalog.warmup, count: 3, profile: profile, intensity: intensity, scale: scale, rest: 15)

        let strengthPool = ExerciseCatalog.availableStrength(for: profile.equipment)
            .filter { levelAllows($0.minLevel, profile.level) }
        let strengthExercises = pick(from: strengthPool, splitIndex: splitIndex, count: profile.goal == .strengthMass ? 5 : 4)
        let strengthRest = profile.goal == .strengthMass ? 75 : 45
        let strengthBlock = block(.strength, from: strengthExercises, count: strengthExercises.count, profile: profile, intensity: intensity, scale: scale, rest: strengthRest)

        var blocks = [warmupBlock, strengthBlock]

        if includeCircuit(for: profile.goal, label: label) {
            let circuitPool = ExerciseCatalog.circuit.filter { !( $0.skipOverForty && profile.ageBand == .over40 ) }
            let circuitExercises = pick(from: circuitPool, splitIndex: splitIndex, count: profile.goal == .militaryEndurance ? 5 : 4)
            let circuitRest = profile.goal == .fatLoss ? 30 : 40
            blocks.append(block(.circuit, from: circuitExercises, count: circuitExercises.count, profile: profile, intensity: intensity, scale: scale, rest: circuitRest))
        }

        let corePool = profile.goal == .mobility ? ExerciseCatalog.mobility : ExerciseCatalog.core
        let coreExercises = pick(from: corePool, splitIndex: splitIndex, count: 3)
        blocks.append(block(.core, from: coreExercises, count: coreExercises.count, profile: profile, intensity: intensity, scale: scale, rest: 20))

        blocks.append(block(.cooldown, from: ExerciseCatalog.cooldown, count: 3, profile: profile, intensity: intensity, scale: scale, rest: 10))

        return DailyWorkout(dayLabel: label, blocks: blocks)
    }

    private static func includeCircuit(for goal: Goal, label: String) -> Bool {
        switch goal {
        case .fatLoss, .militaryEndurance: return true
        case .strengthMass: return label == "day.conditioning"
        case .mobility: return false
        }
    }

    private static func levelAllows(_ required: FitnessLevel, _ userLevel: FitnessLevel) -> Bool {
        rank(userLevel) >= rank(required)
    }

    private static func rank(_ level: FitnessLevel) -> Int {
        switch level {
        case .beginner: return 0
        case .intermediate: return 1
        case .advanced: return 2
        }
    }

    private static func pick(from pool: [CatalogExercise], splitIndex: Int, count: Int) -> [CatalogExercise] {
        guard !pool.isEmpty else { return [] }
        let rotated = Array(pool[(splitIndex % pool.count)...] + pool[..<(splitIndex % pool.count)])
        return Array(rotated.prefix(count))
    }

    private static func block(_ kind: BlockKind, from catalog: [CatalogExercise], count: Int, profile: UserProfile, intensity: Double, scale: Double, rest: Int) -> WorkoutBlock {
        let exercises = catalog.prefix(count).map { entry -> PlannedExercise in
            let sets = kind == .warmup || kind == .cooldown ? 1 : (kind == .strength ? 4 : 3)
            var reps: Int? = nil
            var seconds: Int? = nil
            if let base = entry.baseReps {
                reps = max(4, Int((Double(base) * intensity * scale).rounded()))
            }
            if let base = entry.baseSeconds {
                seconds = max(10, Int((Double(base) * intensity * scale).rounded()))
            }
            return PlannedExercise(name: entry.name, sets: sets, reps: reps, seconds: seconds, restSeconds: rest)
        }
        return WorkoutBlock(kind: kind, exercises: Array(exercises))
    }
}
