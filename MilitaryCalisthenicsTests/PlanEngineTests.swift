import XCTest
@testable import MilitaryCalisthenics

final class PlanEngineTests: XCTestCase {

    private func makeProfile(
        weightKg: Double = 78,
        heightCm: Double = 178,
        age: Int = 28,
        level: FitnessLevel = .intermediate,
        goal: Goal = .fatLoss,
        daysPerWeek: Int = 4,
        equipment: Equipment = .bodyweightOnly
    ) -> UserProfile {
        UserProfile(
            weightKg: weightKg, heightCm: heightCm, age: age, sex: .unspecified,
            level: level, goal: goal, daysPerWeek: daysPerWeek, equipment: equipment
        )
    }

    func testGeneratesAcrossFullInputMatrixWithoutCrashing() {
        let ages = [16, 65]
        let weights = [45.0, 140.0]
        for age in ages {
            for weight in weights {
                for goal in Goal.allCases {
                    for level in FitnessLevel.allCases {
                        for equipment in Equipment.allCases {
                            for days in [3, 6] {
                                let profile = makeProfile(
                                    weightKg: weight, age: age, level: level,
                                    goal: goal, daysPerWeek: days, equipment: equipment
                                )
                                let plan = PlanEngine.generate(for: profile)
                                XCTAssertEqual(plan.weeks.count, level.progressionWeeks)
                                XCTAssertFalse(plan.weeks.isEmpty)
                                for week in plan.weeks {
                                    XCTAssertEqual(week.days.count, days)
                                    for day in week.days {
                                        XCTAssertFalse(day.blocks.isEmpty)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func testGenerationIsDeterministic() {
        let profile = makeProfile()
        let planA = PlanEngine.generate(for: profile)
        let planB = PlanEngine.generate(for: profile)
        XCTAssertEqual(planA, planB)
    }

    private func totalStrengthReps(_ plan: WeeklyPlan) -> Int {
        plan.weeks.first?.days
            .flatMap { $0.blocks }
            .filter { $0.kind == .strength }
            .flatMap { $0.exercises }
            .compactMap { $0.reps }
            .reduce(0, +) ?? 0
    }

    func testAdvancedLevelProducesMoreVolumeThanBeginner() {
        let beginner = PlanEngine.generate(for: makeProfile(level: .beginner))
        let advanced = PlanEngine.generate(for: makeProfile(level: .advanced))
        XCTAssertGreaterThan(totalStrengthReps(advanced), totalStrengthReps(beginner))
    }

    func testHighBMISignalReducesIntensityVersusLowBMIAtEqualLevel() {
        // Same height/age/level/goal, only weight differs -> BMI differs.
        let lowBMI = PlanEngine.generate(for: makeProfile(weightKg: 55, heightCm: 178))
        let highBMI = PlanEngine.generate(for: makeProfile(weightKg: 130, heightCm: 178))
        XCTAssertNotEqual(totalStrengthReps(lowBMI), totalStrengthReps(highBMI))
        XCTAssertGreaterThan(totalStrengthReps(lowBMI), totalStrengthReps(highBMI))
    }

    func testOverFortyReducesIntensityVersusUnderThirtyAtEqualLevel() {
        let younger = PlanEngine.generate(for: makeProfile(age: 25))
        let older = PlanEngine.generate(for: makeProfile(age: 55))
        XCTAssertGreaterThan(totalStrengthReps(younger), totalStrengthReps(older))
    }

    func testWeightRecalibrationChangesGeneratedPlan() {
        let baseline = makeProfile(weightKg: 78)
        var updated = baseline
        updated.weightKg = 95

        let planBefore = PlanEngine.generate(for: baseline)
        let planAfter = PlanEngine.generate(for: updated)

        XCTAssertNotEqual(totalStrengthReps(planBefore), totalStrengthReps(planAfter))
    }

    func testStrengthMassGoalRequestsMoreExercisesThanOtherGoals() {
        let strengthMass = PlanEngine.generate(for: makeProfile(goal: .strengthMass))
        let fatLoss = PlanEngine.generate(for: makeProfile(goal: .fatLoss))

        let strengthMassCount = strengthMass.weeks.first?.days.first?.blocks
            .first(where: { $0.kind == .strength })?.exercises.count ?? 0
        let fatLossCount = fatLoss.weeks.first?.days.first?.blocks
            .first(where: { $0.kind == .strength })?.exercises.count ?? 0

        XCTAssertGreaterThan(strengthMassCount, fatLossCount)
    }

    func testEveryCatalogExerciseCueHasPortugueseAndEnglishTranslations() {
        let allExercises = ExerciseCatalog.warmup + ExerciseCatalog.strengthBodyweight
            + ExerciseCatalog.strengthPullBar + ExerciseCatalog.strengthParallettes
            + ExerciseCatalog.circuit + ExerciseCatalog.core + ExerciseCatalog.mobility
            + ExerciseCatalog.cooldown

        for exercise in allExercises {
            let cueKey = ExerciseMotion.cueKey(for: exercise.name)
            let entry = Translations.table[cueKey]
            XCTAssertNotNil(entry?[.pt], "Missing PT cue translation for \(cueKey) (\(exercise.name))")
            XCTAssertNotNil(entry?[.en], "Missing EN cue translation for \(cueKey) (\(exercise.name))")
        }
    }

    func testEveryCatalogExerciseHasPortugueseAndEnglishTranslations() {
        let allExercises = ExerciseCatalog.warmup + ExerciseCatalog.strengthBodyweight
            + ExerciseCatalog.strengthPullBar + ExerciseCatalog.strengthParallettes
            + ExerciseCatalog.circuit + ExerciseCatalog.core + ExerciseCatalog.mobility
            + ExerciseCatalog.cooldown

        for exercise in allExercises {
            let entry = Translations.table[exercise.name]
            XCTAssertNotNil(entry?[.pt], "Missing PT translation for \(exercise.name)")
            XCTAssertNotNil(entry?[.en], "Missing EN translation for \(exercise.name)")
        }
    }

    func testEveryDayLabelHasPortugueseAndEnglishTranslations() {
        let dayKeys = [
            "day.upper", "day.lower", "day.fullBody", "day.fullBody1", "day.fullBody2",
            "day.fullBody3", "day.push", "day.pull", "day.conditioning", "day.mobility",
        ]
        for key in dayKeys {
            let entry = Translations.table[key]
            XCTAssertNotNil(entry?[.pt], "Missing PT translation for \(key)")
            XCTAssertNotNil(entry?[.en], "Missing EN translation for \(key)")
        }
    }
}
