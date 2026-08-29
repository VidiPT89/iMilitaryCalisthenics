import Foundation

struct CatalogExercise {
    let name: String
    let block: BlockKind
    let baseReps: Int?
    let baseSeconds: Int?
    let minLevel: FitnessLevel
    let skipOverForty: Bool
    let requires: Equipment?
    /// Movement pattern for `.strength` exercises, used to filter selection
    /// by the day's own focus (upper/lower/push/pull). `nil` for exercises
    /// outside the strength block, where it doesn't apply.
    let pattern: MovementPattern?

    init(name: String, block: BlockKind, baseReps: Int? = nil, baseSeconds: Int? = nil,
         minLevel: FitnessLevel = .beginner, skipOverForty: Bool = false, requires: Equipment? = nil,
         pattern: MovementPattern? = nil) {
        self.name = name
        self.block = block
        self.baseReps = baseReps
        self.baseSeconds = baseSeconds
        self.minLevel = minLevel
        self.skipOverForty = skipOverForty
        self.requires = requires
        self.pattern = pattern
    }
}

enum ExerciseCatalog {
    static let warmup: [CatalogExercise] = [
        CatalogExercise(name: "exercise.jumpingJacks", block: .warmup, baseSeconds: 40),
        CatalogExercise(name: "exercise.armCircles", block: .warmup, baseSeconds: 30),
        CatalogExercise(name: "exercise.legSwings", block: .warmup, baseSeconds: 30),
        CatalogExercise(name: "exercise.highKneesWarmup", block: .warmup, baseSeconds: 30),
        CatalogExercise(name: "exercise.bodyweightSquatsWarmup", block: .warmup, baseReps: 12),
    ]

    static let strengthBodyweight: [CatalogExercise] = [
        CatalogExercise(name: "exercise.pushUps", block: .strength, baseReps: 12, pattern: .push),
        CatalogExercise(name: "exercise.widePushUps", block: .strength, baseReps: 10, pattern: .push),
        CatalogExercise(name: "exercise.diamondPushUps", block: .strength, baseReps: 8, minLevel: .intermediate, pattern: .push),
        CatalogExercise(name: "exercise.pikePushUps", block: .strength, baseReps: 8, minLevel: .intermediate, pattern: .push),
        CatalogExercise(name: "exercise.squats", block: .strength, baseReps: 18, pattern: .legs),
        CatalogExercise(name: "exercise.lunges", block: .strength, baseReps: 12, pattern: .legs),
        CatalogExercise(name: "exercise.gluteBridges", block: .strength, baseReps: 15, pattern: .legs),
    ]

    /// Bodyweight-only pull option (no bar needed) — without it, users on
    /// `.bodyweightOnly` equipment had zero pull-pattern exercises available.
    static let strengthPullFallback: [CatalogExercise] = [
        CatalogExercise(name: "exercise.invertedRows", block: .strength, baseReps: 10, pattern: .pull),
    ]

    static let strengthPullBar: [CatalogExercise] = [
        CatalogExercise(name: "exercise.pullUps", block: .strength, baseReps: 6, minLevel: .intermediate, requires: .pullUpBar, pattern: .pull),
        CatalogExercise(name: "exercise.chinUps", block: .strength, baseReps: 6, requires: .pullUpBar, pattern: .pull),
        CatalogExercise(name: "exercise.negativePullUps", block: .strength, baseReps: 5, requires: .pullUpBar, pattern: .pull),
        CatalogExercise(name: "exercise.hangingLegRaises", block: .core, baseReps: 10, minLevel: .intermediate, requires: .pullUpBar),
    ]

    static let strengthParallettes: [CatalogExercise] = [
        CatalogExercise(name: "exercise.dips", block: .strength, baseReps: 10, requires: .parallettes, pattern: .push),
        CatalogExercise(name: "exercise.lSit", block: .core, baseSeconds: 15, minLevel: .advanced, requires: .parallettes),
    ]

    static let circuit: [CatalogExercise] = [
        CatalogExercise(name: "exercise.burpees", block: .circuit, baseReps: 12, skipOverForty: true),
        CatalogExercise(name: "exercise.mountainClimbers", block: .circuit, baseSeconds: 30),
        CatalogExercise(name: "exercise.jumpSquats", block: .circuit, baseReps: 14, skipOverForty: true),
        CatalogExercise(name: "exercise.highKneesCircuit", block: .circuit, baseSeconds: 30),
        CatalogExercise(name: "exercise.bearCrawl", block: .circuit, baseSeconds: 30),
        CatalogExercise(name: "exercise.sprints", block: .circuit, baseSeconds: 20),
        CatalogExercise(name: "exercise.shuttleRuns", block: .circuit, baseSeconds: 30),
    ]

    static let core: [CatalogExercise] = [
        CatalogExercise(name: "exercise.plank", block: .core, baseSeconds: 30),
        CatalogExercise(name: "exercise.sidePlank", block: .core, baseSeconds: 20),
        CatalogExercise(name: "exercise.mountainClimbersCore", block: .core, baseSeconds: 25),
    ]

    static let mobility: [CatalogExercise] = [
        CatalogExercise(name: "exercise.hipOpeners", block: .core, baseSeconds: 30),
        CatalogExercise(name: "exercise.catCow", block: .core, baseSeconds: 30),
        CatalogExercise(name: "exercise.shoulderCircles", block: .core, baseSeconds: 30),
    ]

    static let cooldown: [CatalogExercise] = [
        CatalogExercise(name: "exercise.hamstringStretch", block: .cooldown, baseSeconds: 30),
        CatalogExercise(name: "exercise.quadStretch", block: .cooldown, baseSeconds: 30),
        CatalogExercise(name: "exercise.childsPose", block: .cooldown, baseSeconds: 40),
        CatalogExercise(name: "exercise.deepBreathing", block: .cooldown, baseSeconds: 60),
    ]

    static func availableStrength(for equipment: Equipment) -> [CatalogExercise] {
        var pool = strengthBodyweight
        if equipment == .pullUpBar || equipment == .parallettes {
            pool += strengthPullBar
        } else {
            pool += strengthPullFallback
        }
        if equipment == .parallettes { pool += strengthParallettes }
        return pool
    }
}
