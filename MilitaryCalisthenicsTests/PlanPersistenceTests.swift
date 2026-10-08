import XCTest
import SwiftData
@testable import MilitaryCalisthenics

final class PlanPersistenceTests: XCTestCase {
    private func container() throws -> ModelContainer {
        try ModelContainer(for: PersistedProfile.self, WeightEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    func testFailedProfileSaveRollsBackAndKeepsPreviousProgress() throws {
        let container = try container()
        let context = ModelContext(container)
        var failWrites = false
        let model = PlanViewModel { context in
            if failWrites { throw NSError(domain: "test", code: 1) }
            try context.save()
        }
        model.load(context: context)
        XCTAssertTrue(model.save(profile: .empty))
        model.toggleCompleted("progress-marker")
        model.selectedWeekIndex = 2
        var changed = UserProfile.empty
        changed.age = 35
        failWrites = true
        XCTAssertFalse(model.save(profile: changed))
        XCTAssertEqual(model.profile, .empty)
        XCTAssertEqual(model.completedExerciseIDs, ["progress-marker"])
        XCTAssertEqual(model.selectedWeekIndex, 2)
        XCTAssertEqual(model.storageErrorKey, "storage.saveError")
        let reloaded = PlanViewModel()
        reloaded.load(context: context)
        XCTAssertEqual(reloaded.profile, .empty)
        XCTAssertEqual(reloaded.completedExerciseIDs, ["progress-marker"])
    }

    func testFailedWeightDeletionKeepsHistoryAndCalibration() throws {
        let container = try container()
        let context = ModelContext(container)
        var failWrites = false
        let model = PlanViewModel { context in
            if failWrites { throw NSError(domain: "test", code: 1) }
            try context.save()
        }
        model.load(context: context)
        model.save(profile: .empty)
        model.logWeight(80, on: Date(timeIntervalSince1970: 1))
        model.logWeight(90, on: Date(timeIntervalSince1970: 2))
        failWrites = true
        model.deleteWeightEntry(try XCTUnwrap(model.weightHistory.last))
        XCTAssertEqual(model.profile?.weightKg, 90)
        XCTAssertEqual(try context.fetch(FetchDescriptor<WeightEntry>()).count, 2)
        XCTAssertEqual(model.weightHistory.count, 2)
        failWrites = false
        XCTAssertTrue(model.logWeight(85, on: Date(timeIntervalSince1970: 3)))
        XCTAssertEqual(model.profile?.weightKg, 85)
        XCTAssertNil(model.storageErrorKey)
    }

    func testInvalidStoredProfileDoesNotBecomeAnEmptyOnboardingState() throws {
        let container = try container()
        let context = ModelContext(container)
        let stored = PersistedProfile(profile: .empty)
        stored.age = 0
        context.insert(stored)
        try context.save()
        let model = PlanViewModel()
        model.load(context: context)
        XCTAssertFalse(model.hasLoaded)
        XCTAssertEqual(model.storageErrorKey, "storage.readError")
        XCTAssertFalse(model.save(profile: .empty))
        XCTAssertEqual(try context.fetch(FetchDescriptor<PersistedProfile>()).first?.age, 0)
    }

    func testSavingUnchangedProfilePreservesProgressAndSelection() throws {
        let container = try container()
        let model = PlanViewModel()
        model.load(context: ModelContext(container))
        model.save(profile: .empty)
        model.toggleCompleted("progress-marker")
        model.selectedWeekIndex = 2
        XCTAssertTrue(model.save(profile: .empty))
        XCTAssertEqual(model.completedExerciseIDs, ["progress-marker"])
        XCTAssertEqual(model.selectedWeekIndex, 2)
    }
}
