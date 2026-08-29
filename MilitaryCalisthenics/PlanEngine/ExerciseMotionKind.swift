import Foundation

/// A small set of reusable stick-figure motion archetypes. Every catalog
/// exercise maps onto one of these so a single animated drawing routine
/// (see `ExerciseMotionPose`) can cover the whole exercise list without a
/// bespoke keyframe set per exercise.
enum ExerciseMotionKind {
    case pushUp
    case squat
    case lunge
    case bridge
    case pullUp
    case hangingLegRaise
    case dip
    case lSit
    case burpee
    case mountainClimber
    case highKnees
    case bearCrawl
    case sprint
    case plank
    case sidePlank
    case twist
    case legRaiseFloor
    case crunch
    case superman
    case jumpingJack
    case armCircle
    case legSwing
    case gentleSway
    case staticHold
    case hamstringStretch
    case quadStretch
    case childsPose
    case deepBreathing
    case catCow
    case hipOpen
    case shoulderRoll
}

enum ExerciseMotion {
    /// Maps a catalog exercise's localization key to its motion archetype
    /// and a short coaching cue key. Falls back to `.staticHold` /
    /// "cue.generic" for anything not explicitly listed.
    static func kind(for exerciseKey: String) -> ExerciseMotionKind {
        table[exerciseKey]?.0 ?? .staticHold
    }

    static func cueKey(for exerciseKey: String) -> String {
        table[exerciseKey]?.1 ?? "cue.generic"
    }

    private static let table: [String: (ExerciseMotionKind, String)] = [
        "exercise.jumpingJacks": (.jumpingJack, "cue.jumpingJack"),
        "exercise.armCircles": (.armCircle, "cue.armCircle"),
        "exercise.legSwings": (.legSwing, "cue.legSwing"),
        "exercise.highKneesWarmup": (.highKnees, "cue.highKnees"),
        "exercise.bodyweightSquatsWarmup": (.squat, "cue.squat"),

        "exercise.pushUps": (.pushUp, "cue.pushUp"),
        "exercise.widePushUps": (.pushUp, "cue.pushUpWide"),
        "exercise.diamondPushUps": (.pushUp, "cue.pushUpDiamond"),
        "exercise.pikePushUps": (.pushUp, "cue.pushUpPike"),
        "exercise.squats": (.squat, "cue.squat"),
        "exercise.lunges": (.lunge, "cue.lunge"),
        "exercise.gluteBridges": (.bridge, "cue.bridge"),

        "exercise.invertedRows": (.pullUp, "cue.invertedRows"),

        "exercise.pullUps": (.pullUp, "cue.pullUp"),
        "exercise.chinUps": (.pullUp, "cue.chinUp"),
        "exercise.negativePullUps": (.pullUp, "cue.negativePullUp"),
        "exercise.hangingLegRaises": (.hangingLegRaise, "cue.hangingLegRaise"),

        "exercise.dips": (.dip, "cue.dip"),
        "exercise.lSit": (.lSit, "cue.lSit"),

        "exercise.burpees": (.burpee, "cue.burpee"),
        "exercise.mountainClimbers": (.mountainClimber, "cue.mountainClimber"),
        "exercise.jumpSquats": (.squat, "cue.jumpSquat"),
        "exercise.highKneesCircuit": (.highKnees, "cue.highKnees"),
        "exercise.bearCrawl": (.bearCrawl, "cue.bearCrawl"),
        "exercise.sprints": (.sprint, "cue.sprint"),
        "exercise.shuttleRuns": (.sprint, "cue.shuttleRun"),

        "exercise.plank": (.plank, "cue.plank"),
        "exercise.sidePlank": (.sidePlank, "cue.sidePlank"),
        "exercise.mountainClimbersCore": (.mountainClimber, "cue.mountainClimber"),
        "exercise.russianTwists": (.twist, "cue.russianTwists"),
        "exercise.legRaisesFloor": (.legRaiseFloor, "cue.legRaisesFloor"),
        "exercise.bicycleCrunches": (.crunch, "cue.bicycleCrunches"),
        "exercise.supermanHold": (.superman, "cue.supermanHold"),

        "exercise.hipOpeners": (.hipOpen, "cue.hipOpeners"),
        "exercise.catCow": (.catCow, "cue.catCow"),
        "exercise.shoulderCircles": (.shoulderRoll, "cue.shoulderCircles"),
        "exercise.thoracicRotations": (.shoulderRoll, "cue.thoracicRotations"),
        "exercise.ankleCircles": (.legSwing, "cue.ankleCircles"),
        "exercise.deepSquatHold": (.squat, "cue.deepSquatHold"),

        "exercise.explosivePushUps": (.pushUp, "cue.explosivePushUps"),

        "exercise.hamstringStretch": (.hamstringStretch, "cue.hamstringStretch"),
        "exercise.quadStretch": (.quadStretch, "cue.quadStretch"),
        "exercise.childsPose": (.childsPose, "cue.childsPose"),
        "exercise.deepBreathing": (.deepBreathing, "cue.deepBreathing"),
    ]
}
