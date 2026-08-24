import Foundation
import SwiftData

/// A single logged bodyweight measurement. Kept as history (rather than
/// overwriting the profile's current weight) so the plan can be
/// recalibrated over time and the user can see a trend.
@Model
final class WeightEntry {
    var date: Date
    var weightKg: Double

    init(date: Date, weightKg: Double) {
        self.date = date
        self.weightKg = weightKg
    }
}
