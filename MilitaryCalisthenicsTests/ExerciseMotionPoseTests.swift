import XCTest
@testable import MilitaryCalisthenics

final class ExerciseMotionPoseTests: XCTestCase {

    private static let allKinds: [ExerciseMotionKind] = [
        .pushUp, .squat, .lunge, .bridge, .pullUp, .hangingLegRaise, .dip, .lSit,
        .burpee, .mountainClimber, .highKnees, .bearCrawl, .sprint, .plank, .sidePlank,
        .jumpingJack, .armCircle, .legSwing, .gentleSway, .staticHold,
        .hamstringStretch, .quadStretch, .childsPose, .deepBreathing, .catCow,
        .hipOpen, .shoulderRoll,
    ]

    private func points(_ pose: StickPose) -> [CGPoint] {
        [pose.head, pose.neck, pose.hip, pose.elbowL, pose.elbowR, pose.handL, pose.handR,
         pose.kneeL, pose.kneeR, pose.footL, pose.footR]
    }

    private func distance(_ a: StickPose, _ b: StickPose) -> Double {
        zip(points(a), points(b)).reduce(0) { total, pair in
            total + Double(hypot(pair.0.x - pair.1.x, pair.0.y - pair.1.y))
        }
    }

    /// Every archetype must visibly move over its cycle — this is the
    /// "frozen stick figure" regression the developer flagged.
    func testEveryArchetypeAnimatesAcrossItsCycle() {
        for kind in Self.allKinds {
            let a = ExerciseMotionPose.pose(for: kind, phase: 0.0)
            let b = ExerciseMotionPose.pose(for: kind, phase: 0.25)
            let d = distance(a, b)
            XCTAssertGreaterThan(d, 0.01, "\(kind) barely moves between phases (distance \(d))")
        }
    }

    /// Distinct exercises shown side by side in the cool-down/mobility
    /// blocks must not render as the same silhouette.
    func testDistinctCooldownAndMobilityArchetypesLookDifferent() {
        let cooldownAndMobility: [ExerciseMotionKind] = [
            .hamstringStretch, .quadStretch, .childsPose, .deepBreathing, .catCow, .hipOpen, .shoulderRoll,
        ]
        for i in 0..<cooldownAndMobility.count {
            for j in (i + 1)..<cooldownAndMobility.count {
                let a = ExerciseMotionPose.pose(for: cooldownAndMobility[i], phase: 0.0)
                let b = ExerciseMotionPose.pose(for: cooldownAndMobility[j], phase: 0.0)
                let d = distance(a, b)
                XCTAssertGreaterThan(
                    d, 0.15,
                    "\(cooldownAndMobility[i]) and \(cooldownAndMobility[j]) look too similar (distance \(d))"
                )
            }
        }
    }
}
