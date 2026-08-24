import CoreGraphics
import Foundation

/// Joint positions for a stick figure, normalized to a 0...1 unit square
/// (origin top-left, y grows downward). `ExerciseDemoView` scales this to
/// the drawing surface.
struct StickPose {
    var head: CGPoint
    var neck: CGPoint
    var hip: CGPoint
    var elbowL: CGPoint
    var elbowR: CGPoint
    var handL: CGPoint
    var handR: CGPoint
    var kneeL: CGPoint
    var kneeR: CGPoint
    var footL: CGPoint
    var footR: CGPoint
    /// 0 = standing figure, 1 = fully horizontal (rotates the scene for
    /// floor-based exercises like push-ups, planks, mountain climbers).
    var horizontal: Bool = false
}

enum ExerciseMotionPose {
    /// `phase` is 0...1 and loops continuously.
    static func pose(for kind: ExerciseMotionKind, phase: Double) -> StickPose {
        let s = sin(phase * 2 * .pi)          // -1...1 smooth cycle
        let s01 = (s + 1) / 2                  // 0...1
        let alt = sin((phase + 0.5) * 2 * .pi) // opposite-phase cycle

        switch kind {
        case .pushUp:
            let lower = 0.15 * s01
            let y = 0.45 + lower
            return StickPose(
                head: CGPoint(x: 0.16, y: y - 0.02),
                neck: CGPoint(x: 0.24, y: y),
                hip: CGPoint(x: 0.62, y: y + 0.02),
                elbowL: CGPoint(x: 0.28, y: y + 0.10 + lower * 0.6),
                elbowR: CGPoint(x: 0.30, y: y + 0.12 + lower * 0.6),
                handL: CGPoint(x: 0.26, y: 0.78), handR: CGPoint(x: 0.32, y: 0.78),
                kneeL: CGPoint(x: 0.80, y: y + 0.06), kneeR: CGPoint(x: 0.82, y: y + 0.06),
                footL: CGPoint(x: 0.94, y: 0.78), footR: CGPoint(x: 0.96, y: 0.78),
                horizontal: true
            )

        case .squat:
            let depth = 0.18 * s01
            return standing(hipDrop: depth, kneeBend: depth * 1.4)

        case .lunge:
            let depth = 0.14 * s01
            var p = standing(hipDrop: depth * 0.5, kneeBend: 0)
            p.kneeL = CGPoint(x: 0.40, y: 0.72 + depth)
            p.footL = CGPoint(x: 0.34, y: 0.92)
            p.kneeR = CGPoint(x: 0.58, y: 0.68 + depth * 0.4)
            p.footR = CGPoint(x: 0.66, y: 0.95)
            return p

        case .bridge:
            let lift = 0.14 * s01
            return StickPose(
                head: CGPoint(x: 0.14, y: 0.86), neck: CGPoint(x: 0.24, y: 0.86),
                hip: CGPoint(x: 0.55, y: 0.86 - lift),
                elbowL: CGPoint(x: 0.20, y: 0.80), elbowR: CGPoint(x: 0.20, y: 0.92),
                handL: CGPoint(x: 0.20, y: 0.70), handR: CGPoint(x: 0.20, y: 0.70),
                kneeL: CGPoint(x: 0.72, y: 0.70), kneeR: CGPoint(x: 0.74, y: 0.70),
                footL: CGPoint(x: 0.70, y: 0.90), footR: CGPoint(x: 0.72, y: 0.90),
                horizontal: true
            )

        case .pullUp:
            let lift = 0.16 * s01
            let barY = 0.14
            return StickPose(
                head: CGPoint(x: 0.5, y: 0.24 - lift), neck: CGPoint(x: 0.5, y: barY + 0.10 - lift),
                hip: CGPoint(x: 0.5, y: 0.56 - lift * 0.6),
                elbowL: CGPoint(x: 0.38, y: barY + 0.10 - lift * 0.4), elbowR: CGPoint(x: 0.62, y: barY + 0.10 - lift * 0.4),
                handL: CGPoint(x: 0.40, y: barY), handR: CGPoint(x: 0.60, y: barY),
                kneeL: CGPoint(x: 0.46, y: 0.76 - lift * 0.6), kneeR: CGPoint(x: 0.54, y: 0.76 - lift * 0.6),
                footL: CGPoint(x: 0.44, y: 0.92 - lift * 0.6), footR: CGPoint(x: 0.56, y: 0.92 - lift * 0.6)
            )

        case .hangingLegRaise:
            let raise = 0.34 * s01
            let barY = 0.14
            return StickPose(
                head: CGPoint(x: 0.5, y: 0.24), neck: CGPoint(x: 0.5, y: barY + 0.10),
                hip: CGPoint(x: 0.5, y: 0.52),
                elbowL: CGPoint(x: 0.38, y: barY + 0.10), elbowR: CGPoint(x: 0.62, y: barY + 0.10),
                handL: CGPoint(x: 0.40, y: barY), handR: CGPoint(x: 0.60, y: barY),
                kneeL: CGPoint(x: 0.5, y: 0.52 + 0.18 - raise), kneeR: CGPoint(x: 0.5, y: 0.52 + 0.18 - raise),
                footL: CGPoint(x: 0.5, y: 0.52 + 0.30 - raise * 1.4), footR: CGPoint(x: 0.5, y: 0.52 + 0.30 - raise * 1.4)
            )

        case .dip:
            let lower = 0.14 * s01
            return StickPose(
                head: CGPoint(x: 0.5, y: 0.20 + lower), neck: CGPoint(x: 0.5, y: 0.28 + lower),
                hip: CGPoint(x: 0.5, y: 0.52 + lower),
                elbowL: CGPoint(x: 0.36, y: 0.40 + lower * 1.4), elbowR: CGPoint(x: 0.64, y: 0.40 + lower * 1.4),
                handL: CGPoint(x: 0.36, y: 0.34), handR: CGPoint(x: 0.64, y: 0.34),
                kneeL: CGPoint(x: 0.46, y: 0.70 + lower), kneeR: CGPoint(x: 0.54, y: 0.70 + lower),
                footL: CGPoint(x: 0.44, y: 0.86 + lower), footR: CGPoint(x: 0.56, y: 0.86 + lower)
            )

        case .lSit:
            let bounce = 0.035 * s01
            return StickPose(
                head: CGPoint(x: 0.20, y: 0.40 + bounce), neck: CGPoint(x: 0.28, y: 0.46 + bounce),
                hip: CGPoint(x: 0.42, y: 0.62 + bounce),
                elbowL: CGPoint(x: 0.30, y: 0.60), elbowR: CGPoint(x: 0.30, y: 0.66),
                handL: CGPoint(x: 0.30, y: 0.80), handR: CGPoint(x: 0.30, y: 0.80),
                kneeL: CGPoint(x: 0.66, y: 0.56 + bounce), kneeR: CGPoint(x: 0.68, y: 0.58 + bounce),
                footL: CGPoint(x: 0.90, y: 0.52 + bounce), footR: CGPoint(x: 0.92, y: 0.54 + bounce),
                horizontal: true
            )

        case .burpee:
            // Four beats in one loop: squat down -> kick to plank -> squat -> jump up.
            let t = phase.truncatingRemainder(dividingBy: 1)
            switch t {
            case 0..<0.25:
                let d = t / 0.25
                return standing(hipDrop: 0.20 * d, kneeBend: 0.28 * d)
            case 0.25..<0.5:
                var p = ExerciseMotionPose.pose(for: .plank, phase: 0)
                let d = (t - 0.25) / 0.25
                p.hip.x = 0.40 + 0.22 * d
                p.kneeL.x = 0.75; p.kneeR.x = 0.75
                p.footL.x = 0.94; p.footR.x = 0.94
                return p
            case 0.5..<0.75:
                let d = 1 - (t - 0.5) / 0.25
                return standing(hipDrop: 0.20 * d, kneeBend: 0.28 * d)
            default:
                let d = (t - 0.75) / 0.25
                let jump = sin(d * .pi) * 0.10
                return standing(hipDrop: -jump, kneeBend: 0)
            }

        case .mountainClimber:
            let driveL = max(0, s01 - 0.5) * 2
            let driveR = max(0, ((alt + 1) / 2) - 0.5) * 2
            return StickPose(
                head: CGPoint(x: 0.16, y: 0.44), neck: CGPoint(x: 0.24, y: 0.46),
                hip: CGPoint(x: 0.58, y: 0.48),
                elbowL: CGPoint(x: 0.28, y: 0.58), elbowR: CGPoint(x: 0.30, y: 0.60),
                handL: CGPoint(x: 0.26, y: 0.78), handR: CGPoint(x: 0.32, y: 0.78),
                kneeL: CGPoint(x: 0.68 - driveL * 0.30, y: 0.50 + driveL * 0.14),
                kneeR: CGPoint(x: 0.72 - driveR * 0.30, y: 0.54 + driveR * 0.14),
                footL: CGPoint(x: 0.80 - driveL * 0.40, y: 0.78 - driveL * 0.02),
                footR: CGPoint(x: 0.90 - driveR * 0.40, y: 0.78 - driveR * 0.02),
                horizontal: true
            )

        case .highKnees:
            let liftL = max(0, s01 - 0.5) * 2
            let liftR = max(0, ((alt + 1) / 2) - 0.5) * 2
            return StickPose(
                head: CGPoint(x: 0.5, y: 0.16), neck: CGPoint(x: 0.5, y: 0.26),
                hip: CGPoint(x: 0.5, y: 0.54),
                elbowL: CGPoint(x: 0.38, y: 0.44), elbowR: CGPoint(x: 0.62, y: 0.44),
                handL: CGPoint(x: 0.40, y: 0.36), handR: CGPoint(x: 0.60, y: 0.36),
                kneeL: CGPoint(x: 0.42, y: 0.66 - liftL * 0.22), kneeR: CGPoint(x: 0.58, y: 0.66 - liftR * 0.22),
                footL: CGPoint(x: 0.42, y: 0.90 - liftL * 0.34), footR: CGPoint(x: 0.58, y: 0.90 - liftR * 0.34)
            )

        case .bearCrawl:
            let stepL = sin(phase * 2 * .pi) * 0.10
            let stepR = sin((phase + 0.5) * 2 * .pi) * 0.10
            return StickPose(
                head: CGPoint(x: 0.20, y: 0.40), neck: CGPoint(x: 0.28, y: 0.44),
                hip: CGPoint(x: 0.62, y: 0.46),
                elbowL: CGPoint(x: 0.30, y: 0.58), elbowR: CGPoint(x: 0.32, y: 0.60),
                handL: CGPoint(x: 0.30 + stepL, y: 0.80), handR: CGPoint(x: 0.34 - stepL, y: 0.80),
                kneeL: CGPoint(x: 0.78, y: 0.56), kneeR: CGPoint(x: 0.80, y: 0.58),
                footL: CGPoint(x: 0.86 + stepR, y: 0.80), footR: CGPoint(x: 0.90 - stepR, y: 0.80),
                horizontal: true
            )

        case .sprint:
            let swingL = s * 0.16
            let swingR = alt * 0.16
            return StickPose(
                head: CGPoint(x: 0.56, y: 0.14), neck: CGPoint(x: 0.54, y: 0.24),
                hip: CGPoint(x: 0.5, y: 0.52),
                elbowL: CGPoint(x: 0.5 - swingR * 1.4, y: 0.38), elbowR: CGPoint(x: 0.5 + swingL * 1.4, y: 0.40),
                handL: CGPoint(x: 0.5 - swingR * 2.0, y: 0.30), handR: CGPoint(x: 0.5 + swingL * 2.0, y: 0.48),
                kneeL: CGPoint(x: 0.5 + swingL * 1.2, y: 0.64), kneeR: CGPoint(x: 0.5 - swingR * 1.2, y: 0.66),
                footL: CGPoint(x: 0.5 + swingL * 2.2, y: 0.86), footR: CGPoint(x: 0.5 - swingR * 2.2, y: 0.90)
            )

        case .plank:
            let wobble = 0.02 * s
            return StickPose(
                head: CGPoint(x: 0.14, y: 0.42 + wobble), neck: CGPoint(x: 0.24, y: 0.44 + wobble),
                hip: CGPoint(x: 0.60, y: 0.46 + wobble),
                elbowL: CGPoint(x: 0.26, y: 0.62), elbowR: CGPoint(x: 0.28, y: 0.64),
                handL: CGPoint(x: 0.24, y: 0.80), handR: CGPoint(x: 0.30, y: 0.80),
                kneeL: CGPoint(x: 0.80, y: 0.50 + wobble), kneeR: CGPoint(x: 0.82, y: 0.50 + wobble),
                footL: CGPoint(x: 0.94, y: 0.80), footR: CGPoint(x: 0.96, y: 0.80),
                horizontal: true
            )

        case .sidePlank:
            let lift = 0.045 * s01
            return StickPose(
                head: CGPoint(x: 0.16, y: 0.30 - lift), neck: CGPoint(x: 0.26, y: 0.34 - lift),
                hip: CGPoint(x: 0.58, y: 0.40 - lift),
                elbowL: CGPoint(x: 0.28, y: 0.52), elbowR: CGPoint(x: 0.40, y: 0.16 - lift * 2),
                handL: CGPoint(x: 0.24, y: 0.66), handR: CGPoint(x: 0.44, y: 0.06 - lift * 2),
                kneeL: CGPoint(x: 0.82, y: 0.42 - lift), kneeR: CGPoint(x: 0.84, y: 0.42 - lift),
                footL: CGPoint(x: 0.96, y: 0.44 - lift), footR: CGPoint(x: 0.96, y: 0.44 - lift),
                horizontal: true
            )

        case .jumpingJack:
            let open = s01
            return StickPose(
                head: CGPoint(x: 0.5, y: 0.14), neck: CGPoint(x: 0.5, y: 0.24),
                hip: CGPoint(x: 0.5, y: 0.54),
                elbowL: CGPoint(x: 0.5 - 0.20 - 0.06 * open, y: 0.30 - 0.10 * open),
                elbowR: CGPoint(x: 0.5 + 0.20 + 0.06 * open, y: 0.30 - 0.10 * open),
                handL: CGPoint(x: 0.5 - 0.16 - 0.14 * open, y: 0.44 - 0.28 * open),
                handR: CGPoint(x: 0.5 + 0.16 + 0.14 * open, y: 0.44 - 0.28 * open),
                kneeL: CGPoint(x: 0.5 - 0.10 * open, y: 0.72), kneeR: CGPoint(x: 0.5 + 0.10 * open, y: 0.72),
                footL: CGPoint(x: 0.5 - 0.22 * open, y: 0.92), footR: CGPoint(x: 0.5 + 0.22 * open, y: 0.92)
            )

        case .armCircle:
            let angle = phase * 2 * .pi
            let armX = cos(angle) * 0.18
            let armY = sin(angle) * 0.18
            return StickPose(
                head: CGPoint(x: 0.5, y: 0.16), neck: CGPoint(x: 0.5, y: 0.26),
                hip: CGPoint(x: 0.5, y: 0.56),
                elbowL: CGPoint(x: 0.36, y: 0.36), elbowR: CGPoint(x: 0.64, y: 0.36),
                handL: CGPoint(x: 0.36 - armX, y: 0.36 - armY), handR: CGPoint(x: 0.64 + armX, y: 0.36 - armY),
                kneeL: CGPoint(x: 0.44, y: 0.76), kneeR: CGPoint(x: 0.56, y: 0.76),
                footL: CGPoint(x: 0.44, y: 0.94), footR: CGPoint(x: 0.56, y: 0.94)
            )

        case .legSwing:
            let swing = s * 0.20
            return StickPose(
                head: CGPoint(x: 0.5, y: 0.16), neck: CGPoint(x: 0.5, y: 0.26),
                hip: CGPoint(x: 0.5, y: 0.54),
                elbowL: CGPoint(x: 0.38, y: 0.42), elbowR: CGPoint(x: 0.62, y: 0.42),
                handL: CGPoint(x: 0.40, y: 0.52), handR: CGPoint(x: 0.60, y: 0.52),
                kneeL: CGPoint(x: 0.5, y: 0.74), kneeR: CGPoint(x: 0.5 + swing, y: 0.72),
                footL: CGPoint(x: 0.5, y: 0.94), footR: CGPoint(x: 0.5 + swing * 2, y: 0.90)
            )

        case .gentleSway:
            let sway = s * 0.08
            return StickPose(
                head: CGPoint(x: 0.5 + sway, y: 0.16), neck: CGPoint(x: 0.5 + sway * 0.6, y: 0.26),
                hip: CGPoint(x: 0.5, y: 0.56),
                elbowL: CGPoint(x: 0.36 + sway, y: 0.40), elbowR: CGPoint(x: 0.64 + sway, y: 0.40),
                handL: CGPoint(x: 0.34 + sway, y: 0.52), handR: CGPoint(x: 0.66 + sway, y: 0.52),
                kneeL: CGPoint(x: 0.44, y: 0.76), kneeR: CGPoint(x: 0.56, y: 0.76),
                footL: CGPoint(x: 0.44, y: 0.94), footR: CGPoint(x: 0.56, y: 0.94)
            )

        case .staticHold:
            // Seated/kneeling floor stretch (hamstring/quad stretch, child's
            // pose, deep breathing) — these are grounded holds, not standing
            // poses, with a visible chest-rise breathing motion.
            let breathe = 0.035 * s01
            return StickPose(
                head: CGPoint(x: 0.16, y: 0.58 - breathe * 0.6), neck: CGPoint(x: 0.26, y: 0.60 - breathe * 0.4),
                hip: CGPoint(x: 0.56, y: 0.66),
                elbowL: CGPoint(x: 0.30, y: 0.66 - breathe), elbowR: CGPoint(x: 0.32, y: 0.70 - breathe),
                handL: CGPoint(x: 0.36, y: 0.78 - breathe * 1.4), handR: CGPoint(x: 0.40, y: 0.80 - breathe * 1.4),
                kneeL: CGPoint(x: 0.74, y: 0.60), kneeR: CGPoint(x: 0.78, y: 0.62),
                footL: CGPoint(x: 0.92, y: 0.66), footR: CGPoint(x: 0.94, y: 0.70),
                horizontal: true
            )
        }
    }

    private static func standing(hipDrop: Double, kneeBend: Double) -> StickPose {
        StickPose(
            head: CGPoint(x: 0.5, y: 0.14 + hipDrop * 0.6),
            neck: CGPoint(x: 0.5, y: 0.24 + hipDrop * 0.6),
            hip: CGPoint(x: 0.5, y: 0.54 + hipDrop),
            elbowL: CGPoint(x: 0.34, y: 0.38 + hipDrop * 0.5), elbowR: CGPoint(x: 0.66, y: 0.38 + hipDrop * 0.5),
            handL: CGPoint(x: 0.30, y: 0.50 + hipDrop * 0.3), handR: CGPoint(x: 0.70, y: 0.50 + hipDrop * 0.3),
            kneeL: CGPoint(x: 0.42, y: 0.72 + kneeBend * 0.3), kneeR: CGPoint(x: 0.58, y: 0.72 + kneeBend * 0.3),
            footL: CGPoint(x: 0.40, y: 0.94), footR: CGPoint(x: 0.60, y: 0.94)
        )
    }
}
