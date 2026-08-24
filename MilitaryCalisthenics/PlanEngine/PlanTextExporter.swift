import Foundation

enum PlanTextExporter {
    static func text(for day: DailyWorkout, weekIndex: Int) -> String {
        var lines: [String] = []
        lines.append("\(t("app.name")) — \(t("plan.week")) \(weekIndex + 1) · \(t(day.dayLabel))")
        lines.append("")
        for block in day.blocks {
            lines.append("\(t("block.\(block.kind.rawValue)").uppercased())")
            for exercise in block.exercises {
                lines.append("  • \(line(for: exercise))")
            }
            lines.append("")
        }
        lines.append(t("export.footer"))
        return lines.joined(separator: "\n")
    }

    static func text(for week: WeekPlan) -> String {
        var lines: [String] = []
        lines.append("\(t("app.name")) — \(t("plan.week")) \(week.index + 1)")
        lines.append("")
        for day in week.days {
            lines.append(text(for: day, weekIndex: week.index))
            lines.append("————————————————————")
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    private static func line(for exercise: PlannedExercise) -> String {
        let quantity: String
        if let reps = exercise.reps {
            quantity = "\(exercise.sets) \(t("exercise.sets")) × \(reps) \(t("exercise.reps"))"
        } else if let seconds = exercise.seconds {
            quantity = "\(exercise.sets) \(t("exercise.sets")) × \(seconds)\(t("exercise.seconds"))"
        } else {
            quantity = ""
        }
        return "\(t(exercise.name)) — \(quantity) · \(exercise.restSeconds)s \(t("exercise.rest"))"
    }
}
