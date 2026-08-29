import SwiftUI

/// Full-screen guided session that walks through a day's workout step by
/// step: timed exercises count down automatically, rep-based ones wait for
/// a manual "Done" tap, and rest counts down between them. See
/// docs/plan-engine-spec.md "Guided workout session (timer)".
struct WorkoutSessionView: View {
    let onFinish: () -> Void
    @State private var viewModel: WorkoutSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingExit = false
    let theme = Theme.shared

    init(day: DailyWorkout, onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        _viewModel = State(initialValue: WorkoutSessionViewModel(day: day))
    }

    var body: some View {
        VStack(spacing: 24) {
            header
            Spacer()
            if let step = viewModel.currentStep {
                content(for: step)
            }
            Spacer()
            if let step = viewModel.currentStep {
                controls(for: step)
            }
        }
        .padding(24)
        .background(theme.background)
        .onChange(of: viewModel.isFinished) { _, finished in
            guard finished else { return }
            viewModel.stop()
            onFinish()
            dismiss()
        }
        .onDisappear { viewModel.stop() }
    }

    private var header: some View {
        HStack {
            Button {
                withAnimation(theme.springAnimation) { confirmingExit.toggle() }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.textDim)
                    .padding(10)
                    .background(Circle().fill(theme.panel))
            }
            Spacer()
            if let step = viewModel.currentStep {
                Text(t("block.\(step.blockKind.rawValue)"))
                    .font(.caption.bold())
                    .foregroundStyle(theme.accent)
            }
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .overlay(alignment: .top) {
            if confirmingExit {
                exitConfirmation
                    .offset(y: 56)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var exitConfirmation: some View {
        VStack(spacing: 12) {
            Text(t("session.exitConfirm"))
                .font(.footnote)
                .foregroundStyle(theme.text)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Button(t("session.exitCancel")) {
                    withAnimation(theme.springAnimation) { confirmingExit = false }
                }
                .foregroundStyle(theme.textDim)
                Button(t("session.exitConfirmAction")) {
                    viewModel.stop()
                    dismiss()
                }
                .foregroundStyle(theme.danger)
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(16)
        .panelBackground()
        .zIndex(1)
    }

    @ViewBuilder
    private func content(for step: WorkoutStep) -> some View {
        switch step.kind {
        case .work(let exercise):
            VStack(spacing: 16) {
                Text(t(exercise.name))
                    .font(.title.bold())
                    .foregroundStyle(theme.text)
                    .multilineTextAlignment(.center)
                Text("\(t("exercise.set")) \(step.setIndex + 1)/\(step.totalSets)")
                    .font(.subheadline)
                    .foregroundStyle(theme.textDim)
                if exercise.seconds != nil {
                    Text(timeString(viewModel.remainingSeconds))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accent)
                } else if let reps = exercise.reps {
                    Text("\(reps) \(t("exercise.reps"))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accent)
                }
            }
        case .rest:
            VStack(spacing: 16) {
                Text(t("session.rest"))
                    .font(.title2.bold())
                    .foregroundStyle(theme.ok)
                Text(timeString(viewModel.remainingSeconds))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.text)
            }
        }
    }

    @ViewBuilder
    private func controls(for step: WorkoutStep) -> some View {
        VStack(spacing: 12) {
            switch step.kind {
            case .work(let exercise):
                if exercise.reps != nil {
                    primaryButton(t("session.done")) { viewModel.markDone() }
                } else {
                    pauseButton
                }
            case .rest:
                primaryButton(t("session.skipRest")) { viewModel.skipRest() }
                pauseButton
            }
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(theme.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var pauseButton: some View {
        Button {
            viewModel.togglePause()
        } label: {
            Text(viewModel.isPaused ? t("session.resume") : t("session.pause"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.textDim)
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
