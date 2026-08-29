import Foundation
import Observation

/// One step of a guided workout session: either doing a set of an exercise,
/// or resting before the next one. See docs/plan-engine-spec.md
/// "Guided workout session (timer)".
struct WorkoutStep: Identifiable {
    enum Kind {
        case work(PlannedExercise)
        case rest(afterExercise: PlannedExercise)
    }

    let id = UUID()
    let blockKind: BlockKind
    let kind: Kind
    let setIndex: Int
    let totalSets: Int
}

@Observable
final class WorkoutSessionViewModel {
    private(set) var steps: [WorkoutStep]
    private(set) var currentIndex = 0
    var remainingSeconds: Int = 0
    var isPaused = false
    var isFinished = false

    private var timerTask: Task<Void, Never>?

    init(day: DailyWorkout) {
        steps = Self.buildSteps(day: day)
        startCurrentStep()
    }

    var currentStep: WorkoutStep? {
        steps.indices.contains(currentIndex) ? steps[currentIndex] : nil
    }

    /// Flattens every block into sequential (set, rest) steps, skipping the
    /// rest step after the very last set of the whole day.
    private static func buildSteps(day: DailyWorkout) -> [WorkoutStep] {
        var result: [WorkoutStep] = []
        let lastBlockKind = day.blocks.last?.kind
        for block in day.blocks {
            let lastExerciseName = block.exercises.last?.name
            for exercise in block.exercises {
                for set in 0..<max(exercise.sets, 1) {
                    result.append(WorkoutStep(blockKind: block.kind, kind: .work(exercise), setIndex: set, totalSets: exercise.sets))
                    let isVeryLastSet = block.kind == lastBlockKind && exercise.name == lastExerciseName && set == exercise.sets - 1
                    if !isVeryLastSet {
                        result.append(WorkoutStep(blockKind: block.kind, kind: .rest(afterExercise: exercise), setIndex: set, totalSets: exercise.sets))
                    }
                }
            }
        }
        return result
    }

    private func startCurrentStep() {
        timerTask?.cancel()
        guard let step = currentStep else {
            isFinished = true
            return
        }
        switch step.kind {
        case .work(let exercise):
            if let seconds = exercise.seconds {
                remainingSeconds = seconds
                runCountdown()
            } else {
                remainingSeconds = 0
            }
        case .rest(let exercise):
            remainingSeconds = exercise.restSeconds
            runCountdown()
        }
    }

    private func runCountdown() {
        timerTask = Task { [weak self] in
            while let self, self.remainingSeconds > 0 {
                if Task.isCancelled { return }
                if self.isPaused {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    continue
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled || self.isPaused { continue }
                self.remainingSeconds -= 1
            }
            guard let self, !Task.isCancelled else { return }
            self.advance()
        }
    }

    /// Advances past a rep-based work step, which has no countdown.
    func markDone() { advance() }

    func skipRest() { advance() }

    func skipExercise() { advance() }

    func togglePause() { isPaused.toggle() }

    private func advance() {
        timerTask?.cancel()
        currentIndex += 1
        startCurrentStep()
    }

    func stop() {
        timerTask?.cancel()
    }
}
