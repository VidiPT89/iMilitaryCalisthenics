import XCTest
import SwiftData
@testable import MilitaryCalisthenics

final class PlanEngineTests: XCTestCase {

    private func makeProfile(
        weightKg: Double = 78,
        heightCm: Double = 178,
        age: Int = 28,
        level: FitnessLevel = .intermediate,
        goal: Goal = .fatLoss,
        daysPerWeek: Int = 4,
        equipment: Equipment = .bodyweightOnly,
        sessionMinutes: Int = 30
    ) -> UserProfile {
        UserProfile(
            weightKg: weightKg, heightCm: heightCm, age: age, sex: .unspecified,
            level: level, goal: goal, daysPerWeek: daysPerWeek, equipment: equipment,
            sessionMinutes: sessionMinutes
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

    func testDeletingMostRecentWeightEntryRecalibratesToPreviousOne() throws {
        let container = try ModelContainer(
            for: PersistedProfile.self, WeightEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let viewModel = PlanViewModel()
        viewModel.load(context: context)
        viewModel.save(profile: makeProfile(weightKg: 78))

        viewModel.logWeight(85, on: Date(timeIntervalSince1970: 1))
        viewModel.logWeight(90, on: Date(timeIntervalSince1970: 2))
        XCTAssertEqual(viewModel.profile?.weightKg, 90)
        XCTAssertEqual(viewModel.weightHistory.count, 2)

        guard let mostRecent = viewModel.weightHistory.last else {
            return XCTFail("expected a most recent weight entry")
        }
        viewModel.deleteWeightEntry(mostRecent)

        XCTAssertEqual(viewModel.weightHistory.count, 1)
        XCTAssertEqual(viewModel.profile?.weightKg, 85, "profile should revert to the new most-recent entry")
    }

    func testStrengthMassGoalUsesLongerRestThanFatLoss() {
        // strengthMass favors fewer, heavier movements with more rest between
        // sets rather than more exercises (docs/plan-engine-spec.md "Blocks").
        let strengthMass = PlanEngine.generate(for: makeProfile(goal: .strengthMass))
        let fatLoss = PlanEngine.generate(for: makeProfile(goal: .fatLoss))

        let strengthMassRest = strengthMass.weeks.first?.days.first?.blocks
            .first(where: { $0.kind == .strength })?.exercises.first?.restSeconds ?? 0
        let fatLossRest = fatLoss.weeks.first?.days.first?.blocks
            .first(where: { $0.kind == .strength })?.exercises.first?.restSeconds ?? 0

        XCTAssertGreaterThan(strengthMassRest, fatLossRest)
    }

    func testLongerSessionProducesAtLeastAsManyStrengthExercises() {
        let short = PlanEngine.generate(for: makeProfile(sessionMinutes: 15))
        let long = PlanEngine.generate(for: makeProfile(sessionMinutes: 60))

        let shortCount = short.weeks.first?.days.first?.blocks
            .first(where: { $0.kind == .strength })?.exercises.count ?? 0
        let longCount = long.weeks.first?.days.first?.blocks
            .first(where: { $0.kind == .strength })?.exercises.count ?? 0

        XCTAssertGreaterThanOrEqual(longCount, shortCount)
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

    func testLowerBodyDayOnlyContainsLegExercises() {
        // Regression test: "day.lower" ("Membros Inferiores") used to be a
        // cosmetic label only — the strength block ignored it and could
        // include push-ups/pull exercises on a "lower body" day.
        let profile = makeProfile(daysPerWeek: 4, equipment: .bodyweightOnly)
        let plan = PlanEngine.generate(for: profile)
        let legNames: Set<String> = ["exercise.squats", "exercise.lunges", "exercise.gluteBridges"]

        for week in plan.weeks {
            guard let lowerDay = week.days.first(where: { $0.dayLabel == "day.lower" }) else {
                return XCTFail("expected a day.lower day in a 4-day split")
            }
            let strengthNames = lowerDay.blocks.first(where: { $0.kind == .strength })?.exercises.map(\.name) ?? []
            XCTAssertFalse(strengthNames.isEmpty)
            for name in strengthNames {
                XCTAssertTrue(legNames.contains(name), "\(name) is not a leg exercise but appeared on day.lower")
            }
        }
    }

    func testUpperBodyDayNeverContainsLegExercises() {
        let profile = makeProfile(daysPerWeek: 4, equipment: .bodyweightOnly)
        let plan = PlanEngine.generate(for: profile)
        let legNames: Set<String> = ["exercise.squats", "exercise.lunges", "exercise.gluteBridges"]

        for week in plan.weeks {
            guard let upperDay = week.days.first(where: { $0.dayLabel == "day.upper" }) else {
                return XCTFail("expected a day.upper day in a 4-day split")
            }
            let strengthNames = upperDay.blocks.first(where: { $0.kind == .strength })?.exercises.map(\.name) ?? []
            for name in strengthNames {
                XCTAssertFalse(legNames.contains(name), "\(name) is a leg exercise but appeared on day.upper")
            }
        }
    }

    func testBodyweightOnlyEquipmentHasAPullExercise() {
        // Regression test: bodyweight-only users used to have zero pull-pattern
        // exercises available at all (pull-ups required a bar).
        let pool = ExerciseCatalog.availableStrength(for: .bodyweightOnly)
        XCTAssertTrue(pool.contains(where: { $0.pattern == .pull }), "bodyweight-only pool has no pull exercise")
    }

    func testStrengthSelectionVariesAcrossWeeksOfTheSamePlan() {
        // Regression test: the weekly rotation used to be identical every
        // week of a 4-8 week plan (only varied by day, not by week).
        let profile = makeProfile(level: .advanced, daysPerWeek: 4, equipment: .bodyweightOnly)
        let plan = PlanEngine.generate(for: profile)
        guard plan.weeks.count >= 2 else { return XCTFail("expected multiple weeks") }

        let week1Names = plan.weeks[0].days.first?.blocks.first(where: { $0.kind == .strength })?.exercises.map(\.name)
        let week2Names = plan.weeks[1].days.first?.blocks.first(where: { $0.kind == .strength })?.exercises.map(\.name)
        XCTAssertNotEqual(week1Names, week2Names, "strength selection should vary week to week, not repeat identically")
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
