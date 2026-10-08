import XCTest
@testable import MilitaryCalisthenics

final class PlanOverviewTests: XCTestCase {
    func testLastWeekAloneDoesNotCompletePlan() {
        let plan = PlanEngine.generate(for: .empty)
        let lastIndex = plan.weeks.last!.index
        let lastKeys = Set(plan.exerciseCompletionKeys.filter { $0.hasPrefix("\(lastIndex)-") })
        XCTAssertFalse(plan.isComplete(completedExerciseIDs: lastKeys))
        XCTAssertTrue(plan.isComplete(completedExerciseIDs: Set(plan.exerciseCompletionKeys)))
        XCTAssertFalse(plan.isComplete(completedExerciseIDs: []))
    }

    func testEmptyPlanIsNotComplete() {
        XCTAssertFalse(WeeklyPlan(weeks: [], generatedFor: .empty).isComplete(completedExerciseIDs: []))
    }

    func testDurationMatchesSessionAndExcludesFinalRest() {
        let reps = PlannedExercise(name: "reps", sets: 2, reps: 10, seconds: nil, restSeconds: 20)
        let hold = PlannedExercise(name: "hold", sets: 1, reps: nil, seconds: 45, restSeconds: 10)
        let day = DailyWorkout(dayLabel: "day", blocks: [WorkoutBlock(kind: .strength, exercises: [reps, hold])])
        XCTAssertEqual(day.exerciseCount, 2)
        XCTAssertEqual(day.estimatedDurationSeconds, 145)
        XCTAssertEqual(day.estimatedMinutes, 3)
    }

    func testEmptyWorkoutHasNoDuration() {
        let day = DailyWorkout(dayLabel: "empty", blocks: [])
        XCTAssertEqual(day.exerciseCount, 0)
        XCTAssertEqual(day.estimatedMinutes, 0)
    }
}
