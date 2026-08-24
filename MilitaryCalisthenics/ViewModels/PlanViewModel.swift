import Foundation
import SwiftData
import Observation

@Observable
final class PlanViewModel {
    var profile: UserProfile?
    var plan: WeeklyPlan?
    var selectedWeekIndex: Int = 0
    var selectedDayIndex: Int = 0
    var completedExerciseIDs: Set<String> = []
    var weightHistory: [WeightEntry] = []

    private var context: ModelContext?
    private var storedProfile: PersistedProfile?

    func load(context: ModelContext) {
        self.context = context
        let descriptor = FetchDescriptor<PersistedProfile>()
        if let existing = try? context.fetch(descriptor).first {
            storedProfile = existing
            profile = existing.profile
            completedExerciseIDs = Set(existing.completedExerciseIDs)
            plan = PlanEngine.generate(for: existing.profile)
        }
        reloadWeightHistory()
    }

    private func reloadWeightHistory() {
        guard let context else { return }
        let descriptor = FetchDescriptor<WeightEntry>(sortBy: [SortDescriptor(\.date)])
        weightHistory = (try? context.fetch(descriptor)) ?? []
    }

    /// Logs a new bodyweight measurement, updates the active profile's
    /// current weight and regenerates the plan so future weeks reflect the
    /// new weight, level and goal — without forcing the user back through
    /// onboarding. See docs/plan-engine-spec.md "Weight recalibration".
    func logWeight(_ weightKg: Double, on date: Date = .now) {
        guard let context, var profile else { return }
        let entry = WeightEntry(date: date, weightKg: weightKg)
        context.insert(entry)

        profile.weightKg = weightKg
        self.profile = profile
        storedProfile?.update(from: profile)
        completedExerciseIDs = []
        selectedWeekIndex = 0
        selectedDayIndex = 0
        try? context.save()

        plan = PlanEngine.generate(for: profile)
        reloadWeightHistory()
    }

    /// Removes a logged weight entry. If it was the most recent one, the
    /// active profile's weight (and the generated plan) reverts to the
    /// new most-recent entry, or is left unchanged if no entries remain.
    func deleteWeightEntry(_ entry: WeightEntry) {
        guard let context else { return }
        let wasMostRecent = weightHistory.last === entry
        context.delete(entry)
        try? context.save()
        reloadWeightHistory()

        guard wasMostRecent, var profile, let newest = weightHistory.last else { return }
        profile.weightKg = newest.weightKg
        self.profile = profile
        storedProfile?.update(from: profile)
        try? context.save()
        plan = PlanEngine.generate(for: profile)
    }

    /// Re-runs the plan engine against the current profile without
    /// changing any inputs and resets progress back to week 1 — a lighter
    /// alternative to full re-onboarding for restarting the current plan.
    /// `PlanEngine` is deterministic (same profile -> same plan), so this
    /// intentionally does not produce a randomized variation.
    func regeneratePlan() {
        guard let profile else { return }
        completedExerciseIDs = []
        storedProfile?.completedExerciseIDs = []
        selectedWeekIndex = 0
        selectedDayIndex = 0
        try? context?.save()
        plan = PlanEngine.generate(for: profile)
    }

    func save(profile: UserProfile) {
        guard let context else { return }
        self.profile = profile
        selectedWeekIndex = 0
        selectedDayIndex = 0
        completedExerciseIDs = []
        if let storedProfile {
            storedProfile.update(from: profile)
        } else {
            let new = PersistedProfile(profile: profile)
            context.insert(new)
            storedProfile = new
        }
        try? context.save()
        plan = PlanEngine.generate(for: profile)
    }

    func toggleCompleted(_ exerciseID: String) {
        if completedExerciseIDs.contains(exerciseID) {
            completedExerciseIDs.remove(exerciseID)
        } else {
            completedExerciseIDs.insert(exerciseID)
        }
        storedProfile?.completedExerciseIDs = Array(completedExerciseIDs)
        try? context?.save()
    }

    var currentWeek: WeekPlan? {
        guard let plan, plan.weeks.indices.contains(selectedWeekIndex) else { return nil }
        return plan.weeks[selectedWeekIndex]
    }

    var currentDay: DailyWorkout? {
        guard let week = currentWeek, week.days.indices.contains(selectedDayIndex) else { return nil }
        return week.days[selectedDayIndex]
    }

    var dayCompletionFraction: Double {
        guard let day = currentDay else { return 0 }
        let all = day.blocks.flatMap { $0.exercises }
        guard !all.isEmpty else { return 0 }
        let done = all.filter { completedExerciseIDs.contains(exerciseKey(day: day, exercise: $0)) }.count
        return Double(done) / Double(all.count)
    }

    func exerciseKey(day: DailyWorkout, exercise: PlannedExercise) -> String {
        "\(selectedWeekIndex)-\(day.dayLabel)-\(exercise.name)"
    }
}
