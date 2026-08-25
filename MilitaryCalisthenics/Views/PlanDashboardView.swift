import SwiftUI

struct PlanDashboardView: View {
    var viewModel: PlanViewModel
    let theme = Theme.shared
    @State private var showingPlanComplete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                weekSelector
                if let week = viewModel.currentWeek {
                    if week.isDeload {
                        deloadBanner
                    }
                    daySelector(week: week)
                    progressRing
                    if let day = viewModel.currentDay {
                        VStack(spacing: 16) {
                            ForEach(day.blocks) { block in
                                BlockCard(block: block, day: day, viewModel: viewModel)
                            }
                        }
                        .id(day.id + "\(viewModel.selectedWeekIndex)")
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                } else {
                    Text(t("plan.empty"))
                        .foregroundStyle(theme.textDim)
                        .padding(.top, 60)
                }
            }
            .padding(20)
        }
        .background(theme.background)
        .animation(theme.springAnimation, value: viewModel.selectedDayIndex)
        .onChange(of: viewModel.isPlanComplete) { _, isComplete in
            if isComplete { showingPlanComplete = true }
        }
        .onAppear {
            if viewModel.isPlanComplete { showingPlanComplete = true }
        }
        .sheet(isPresented: $showingPlanComplete) {
            PlanCompleteSheet(viewModel: viewModel, isPresented: $showingPlanComplete)
                .presentationDetents([.medium])
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(t("app.name"))
                    .font(.title2.bold())
                    .foregroundStyle(theme.text)
                if let profile = viewModel.profile {
                    Text(t("onboarding.goal.\(profile.goal.rawValue)"))
                        .font(.caption)
                        .foregroundStyle(theme.accent)
                }
            }
            Spacer()
            if let week = viewModel.currentWeek {
                Menu {
                    if let day = viewModel.currentDay {
                        ShareLink(item: PlanTextExporter.text(for: day, weekIndex: week.index)) {
                            Label(t("export.day"), systemImage: "square.and.arrow.up")
                        }
                    }
                    ShareLink(item: PlanTextExporter.text(for: week)) {
                        Label(t("export.week"), systemImage: "square.and.arrow.up.on.square")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.accent)
                        .padding(10)
                        .background(Circle().fill(theme.panel))
                }
            }
        }
    }

    private var weekSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if let weeks = viewModel.plan?.weeks {
                    ForEach(weeks) { week in
                        let isSelected = week.index == viewModel.selectedWeekIndex
                        Button {
                            withAnimation(theme.springAnimation) {
                                viewModel.selectedWeekIndex = week.index
                                viewModel.selectedDayIndex = 0
                            }
                        } label: {
                            Text("\(t("plan.week")) \(week.index + 1)")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .foregroundStyle(isSelected ? Color.black : theme.textDim)
                                .background(
                                    Capsule().fill(isSelected ? AnyShapeStyle(theme.accentGradient) : AnyShapeStyle(theme.panel))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var deloadBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf.fill")
            Text(t("plan.deload"))
                .font(.footnote.weight(.medium))
        }
        .foregroundStyle(theme.ok)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(theme.ok.opacity(0.12))
        .clipShape(Capsule())
        .transition(.scale.combined(with: .opacity))
    }

    private func daySelector(week: WeekPlan) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(week.days.enumerated()), id: \.offset) { index, day in
                    let isSelected = index == viewModel.selectedDayIndex
                    Button {
                        withAnimation(theme.springAnimation) { viewModel.selectedDayIndex = index }
                    } label: {
                        Text(t(day.dayLabel))
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSelected ? theme.accent : theme.textFaint)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? theme.accent : .clear, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var progressRing: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(theme.panel2, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: viewModel.dayCompletionFraction)
                    .stroke(theme.accentGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(theme.springAnimation, value: viewModel.dayCompletionFraction)
                Text("\(Int(viewModel.dayCompletionFraction * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(theme.text)
            }
            .frame(width: 56, height: 56)

            if let profile = viewModel.profile {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "BMI %.1f", profile.bmi))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(theme.text)
                    Text(t("onboarding.level.\(profile.level.rawValue)"))
                        .font(.caption)
                        .foregroundStyle(theme.textDim)
                }
            }
            Spacer()
        }
        .padding(16)
        .panelBackground()
    }
}

private struct BlockCard: View {
    let block: WorkoutBlock
    let day: DailyWorkout
    var viewModel: PlanViewModel
    let theme = Theme.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("block.\(block.kind.rawValue)"))
                .font(.subheadline.bold())
                .foregroundStyle(theme.accent)

            VStack(spacing: 10) {
                ForEach(block.exercises) { exercise in
                    ExerciseRow(
                        exercise: exercise,
                        isDone: viewModel.completedExerciseIDs.contains(viewModel.exerciseKey(day: day, exercise: exercise))
                    ) {
                        withAnimation(theme.springAnimation) {
                            viewModel.toggleCompleted(viewModel.exerciseKey(day: day, exercise: exercise))
                        }
                    }
                }
            }
        }
        .padding(16)
        .panelBackground()
    }
}

private struct ExerciseRow: View {
    let exercise: PlannedExercise
    let isDone: Bool
    let toggle: () -> Void
    let theme = Theme.shared
    @State private var showingDemo = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                showingDemo = true
            } label: {
                ExerciseDemoThumbnail(motion: ExerciseMotion.kind(for: exercise.name))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("exercise.demoThumbnail.\(exercise.name)")
            .accessibilityLabel(t(exercise.name))
            .accessibilityAddTraits(.isButton)

            Button(action: toggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t(exercise.name))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(isDone ? theme.textFaint : theme.text)
                            .strikethrough(isDone)
                        Text(detailText)
                            .font(.caption)
                            .foregroundStyle(theme.textDim)
                    }
                    Spacer()
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isDone ? theme.ok : theme.textFaint)
                        .scaleEffect(isDone ? 1.1 : 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("exercise.toggle.\(exercise.name)")
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(t(exercise.name)), \(detailText)")
            .accessibilityValue(isDone ? t("exercise.markDone") : "")
            .accessibilityAddTraits(.isButton)
        }
        .sheet(isPresented: $showingDemo) {
            ExerciseDemoSheet(
                exerciseNameKey: exercise.name,
                motion: ExerciseMotion.kind(for: exercise.name),
                cueKey: ExerciseMotion.cueKey(for: exercise.name)
            )
        }
    }

    private var detailText: String {
        let quantity: String
        if let reps = exercise.reps {
            quantity = "\(exercise.sets) \(t("exercise.sets")) × \(reps) \(t("exercise.reps"))"
        } else if let seconds = exercise.seconds {
            quantity = "\(exercise.sets) \(t("exercise.sets")) × \(seconds)\(t("exercise.seconds"))"
        } else {
            quantity = ""
        }
        return "\(quantity) · \(exercise.restSeconds)s \(t("exercise.rest"))"
    }
}

/// Presented when the user finishes the final week of their plan. Offers
/// the two paths the plan engine already supports without re-onboarding:
/// repeating the same level (`regeneratePlan`) or moving to the next one
/// (`levelUp`). See docs/plan-engine-spec.md "Plan completion".
private struct PlanCompleteSheet: View {
    var viewModel: PlanViewModel
    @Binding var isPresented: Bool
    let theme = Theme.shared

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "flag.checkered.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(theme.accentGradient)
                Text(t("planComplete.title"))
                    .font(.title2.bold())
                    .foregroundStyle(theme.text)
                Text(t("planComplete.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(theme.textDim)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            VStack(spacing: 12) {
                if let nextLevel = viewModel.nextLevel {
                    Button {
                        viewModel.levelUp()
                        isPresented = false
                    } label: {
                        optionRow(
                            icon: "arrow.up.circle.fill",
                            title: "\(t("planComplete.levelUp")) \(t("onboarding.level.\(nextLevel.rawValue)"))",
                            subtitle: t("planComplete.levelUp.subtitle"),
                            emphasized: true
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(t("planComplete.maxLevel"))
                        .font(.caption)
                        .foregroundStyle(theme.textDim)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                Button {
                    viewModel.regeneratePlan()
                    isPresented = false
                } label: {
                    optionRow(
                        icon: "arrow.counterclockwise.circle.fill",
                        title: t("planComplete.repeat"),
                        subtitle: t("planComplete.repeat.subtitle"),
                        emphasized: viewModel.nextLevel == nil
                    )
                }
                .buttonStyle(.plain)
            }

            Button(t("planComplete.dismiss")) {
                isPresented = false
            }
            .font(.footnote)
            .foregroundStyle(theme.textFaint)

            Spacer(minLength: 0)
        }
        .padding(20)
        .background(theme.background)
        .interactiveDismissDisabled(false)
    }

    private func optionRow(icon: String, title: String, subtitle: String, emphasized: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(emphasized ? AnyShapeStyle(theme.accentGradient) : AnyShapeStyle(theme.textDim))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.text)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(theme.textDim)
            }
            Spacer()
        }
        .padding(16)
        .panelBackground()
    }
}
