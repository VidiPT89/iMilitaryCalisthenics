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
        self.equipmentRaw = Self.encode(profile.equipment)
        self.sessionMinutes = profile.sessionMinutes
        self.completedExerciseIDs = []
        self.planCompletionAcknowledged = false
    }

    private static func encode(_ equipment: Set<Equipment>) -> String {
        equipment.map(\.rawValue).sorted().joined(separator: ",")
    }

    private static func decode(_ raw: String) -> Set<Equipment> {
        let set = Set(raw.split(separator: ",").compactMap { Equipment(rawValue: String($0)) })
        return set.isEmpty ? [.bodyweightOnly] : set
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
            equipment: Self.decode(equipmentRaw),
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
        equipmentRaw = Self.encode(profile.equipment)
        sessionMinutes = profile.sessionMinutes
        completedExerciseIDs = []
        planCompletionAcknowledged = false
    }
}
