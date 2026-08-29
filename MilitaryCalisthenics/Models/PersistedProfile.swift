import Foundation
import SwiftData

@Model
final class PersistedProfile {
    var weightKg: Double
    var heightCm: Double
    var age: Int
    var sexRaw: String
    var levelRaw: String
    var goalRaw: String
    var daysPerWeek: Int
    var equipmentRaw: String
    var sessionMinutes: Int = 30
    var completedExerciseIDs: [String]
    var planCompletionAcknowledged: Bool = false

    init(profile: UserProfile) {
        self.weightKg = profile.weightKg
        self.heightCm = profile.heightCm
        self.age = profile.age
        self.sexRaw = profile.sex.rawValue
        self.levelRaw = profile.level.rawValue
        self.goalRaw = profile.goal.rawValue
        self.daysPerWeek = profile.daysPerWeek
        self.equipmentRaw = profile.equipment.rawValue
        self.sessionMinutes = profile.sessionMinutes
        self.completedExerciseIDs = []
        self.planCompletionAcknowledged = false
    }

    var profile: UserProfile {
        UserProfile(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            sex: Sex(rawValue: sexRaw) ?? .unspecified,
            level: FitnessLevel(rawValue: levelRaw) ?? .beginner,
            goal: Goal(rawValue: goalRaw) ?? .fatLoss,
            daysPerWeek: daysPerWeek,
            equipment: Equipment(rawValue: equipmentRaw) ?? .bodyweightOnly,
            sessionMinutes: sessionMinutes
        )
    }

    func update(from profile: UserProfile) {
        weightKg = profile.weightKg
        heightCm = profile.heightCm
        age = profile.age
        sexRaw = profile.sex.rawValue
        levelRaw = profile.level.rawValue
        goalRaw = profile.goal.rawValue
        daysPerWeek = profile.daysPerWeek
        equipmentRaw = profile.equipment.rawValue
        sessionMinutes = profile.sessionMinutes
        completedExerciseIDs = []
        planCompletionAcknowledged = false
    }
}
