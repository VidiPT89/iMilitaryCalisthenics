import Foundation
import SwiftData
import Observation

@Observable
final class PlanViewModel {
    private(set) var profile: UserProfile?
    private(set) var plan: WeeklyPlan?
    var selectedWeekIndex = 0
    var selectedDayIndex = 0
    private(set) var completedExerciseIDs: Set<String> = []
    private(set) var weightHistory: [WeightEntry] = []
    private(set) var planCompletionAcknowledged = false
    private(set) var hasLoaded = false
    var storageErrorKey: String?

    private let saveChanges: (ModelContext) throws -> Void

    init(saveChanges: @escaping (ModelContext) throws -> Void = { try $0.save() }) {
        self.saveChanges = saveChanges
    }

    private var context: ModelContext?
    private var storedProfile: PersistedProfile?
    private enum StorageError: Error { case invalidData }

    func load(context: ModelContext) {
        self.context = context
        // All writes below have explicit save/rollback boundaries.
        context.autosaveEnabled = false
        do {
            try refresh()
            storageErrorKey = nil
        } catch {
            hasLoaded = false
            storageErrorKey = "storage.readError"
        }
    }

    private func refresh() throws {
        guard let context else { return }
        let stored = try context.fetch(FetchDescriptor<PersistedProfile>()).first
        let weights = try context.fetch(FetchDescriptor<WeightEntry>(sortBy: [SortDescriptor(\.date)]))
        guard stored?.profile.isValid != false,
              weights.allSatisfy({ (30...250).contains($0.weightKg) && $0.date.timeIntervalSince1970.isFinite }) else {
            throw StorageError.invalidData
        }
        let updatedProfile = stored?.profile
        if profile != updatedProfile || plan == nil {
            plan = updatedProfile.map { PlanEngine.generate(for: $0) }
        }
        storedProfile = stored
        profile = updatedProfile
        completedExerciseIDs = Set(stored?.completedExerciseIDs ?? [])
        planCompletionAcknowledged = stored?.planCompletionAcknowledged ?? false
        weightHistory = weights
        hasLoaded = true
    }

    @discardableResult
    private func commit(resetSelection: Bool = false, _ change: () -> Void) -> Bool {
        guard let context, hasLoaded else { return false }
        change()
        do {
            try saveChanges(context)
        } catch {
            context.rollback()
            storageErrorKey = "storage.saveError"
            return false
        }
        do {
            try refresh()
            if resetSelection { selectedWeekIndex = 0; selectedDayIndex = 0 }
            storageErrorKey = nil
            return true
        } catch {
            hasLoaded = false
            storageErrorKey = "storage.readError"
            return false
        }
    }

    @discardableResult
    func logWeight(_ weightKg: Double, on date: Date = .now) -> Bool {
        guard let context, let profile, (30...250).contains(weightKg),
              date.timeIntervalSince1970.isFinite, date <= .now else { return false }
        let isLatest = weightHistory.last.map { date >= $0.date } ?? true
        let recalibrates = isLatest && profile.weightKg != weightKg
        return commit(resetSelection: recalibrates) {
            if let existing = weightHistory.first(where: { $0.date == date }) {
                existing.weightKg = weightKg
            } else {
                context.insert(WeightEntry(date: date, weightKg: weightKg))
            }
            if recalibrates {
                var updated = profile
                updated.weightKg = weightKg
                storedProfile?.update(from: updated)
            }
        }
    }

    func deleteWeightEntry(_ entry: WeightEntry) {
        guard let context, let profile else { return }
        let remaining = weightHistory.filter { $0 !== entry }
        let isLatest = weightHistory.last === entry
        let weight = remaining.last?.weightKg
        let recalibrates = isLatest && weight != nil && weight != profile.weightKg
        commit(resetSelection: recalibrates) {
            context.delete(entry)
            if recalibrates, let weight {
                var updated = profile
                updated.weightKg = weight
                storedProfile?.update(from: updated)
            }
        }
    }

    func regeneratePlan() {
        guard let storedProfile else { return }
        commit(resetSelection: true) {
            storedProfile.completedExerciseIDs = []
            storedProfile.planCompletionAcknowledged = false
        }
    }

    var isPlanComplete: Bool { plan?.isComplete(completedExerciseIDs: completedExerciseIDs) ?? false }
    var shouldShowPlanComplete: Bool { isPlanComplete && !planCompletionAcknowledged }
    var nextLevel: FitnessLevel? { profile?.level.next }

    func acknowledgePlanComplete() {
        commit { storedProfile?.planCompletionAcknowledged = true }
    }

    func levelUp() {
        guard var updated = profile, let next = updated.level.next else { return }
        updated.level = next
        save(profile: updated)
    }

    @discardableResult
    func save(profile: UserProfile) -> Bool {
        guard let context, hasLoaded, profile.isValid else { return false }
        guard self.profile != profile else { return true }
        return commit(resetSelection: true) {
            if let storedProfile { storedProfile.update(from: profile) }
            else { context.insert(PersistedProfile(profile: profile)) }
        }
    }

    func markDayComplete(_ day: DailyWorkout) {
        let keys = day.blocks.flatMap(\.exercises).map { exerciseKey(day: day, exercise: $0) }
        commit { storedProfile?.completedExerciseIDs = Array(completedExerciseIDs.union(keys)) }
    }

    func toggleCompleted(_ exerciseID: String) {
        var updated = completedExerciseIDs
        if !updated.insert(exerciseID).inserted { updated.remove(exerciseID) }
        commit { storedProfile?.completedExerciseIDs = Array(updated) }
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
        let exercises = day.blocks.flatMap(\.exercises)
        guard !exercises.isEmpty else { return 0 }
        let done = exercises.filter { completedExerciseIDs.contains(exerciseKey(day: day, exercise: $0)) }.count
        return Double(done) / Double(exercises.count)
    }

    func exerciseKey(day: DailyWorkout, exercise: PlannedExercise) -> String {
        exerciseKey(weekIndex: selectedWeekIndex, day: day, exercise: exercise)
    }

    func exerciseKey(weekIndex: Int, day: DailyWorkout, exercise: PlannedExercise) -> String {
        "\(weekIndex)-\(day.dayLabel)-\(exercise.name)"
    }
}
