import SwiftUI

struct OnboardingView: View {
    var viewModel: PlanViewModel

    @State private var weightText = "75"
    @State private var heightText = "175"
    @State private var ageText = "28"
    @State private var sex: Sex = .unspecified
    @State private var level: FitnessLevel = .beginner
    @State private var goal: Goal = .fatLoss
    @State private var daysPerWeek: Int = 4
    @State private var equipment: Equipment = .bodyweightOnly
    @State private var showError = false
    @State private var appear = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                Text(t("onboarding.title"))
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.text)
                    .padding(.top, 24)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 12)

                measurementsSection
                selectorSection(title: t("onboarding.sex"), selection: $sex, labelKey: { "onboarding.sex.\($0.rawValue)" })
                selectorSection(title: t("onboarding.level"), selection: $level, labelKey: { "onboarding.level.\($0.rawValue)" })
                selectorSection(title: t("onboarding.goal"), selection: $goal, labelKey: { "onboarding.goal.\($0.rawValue)" })
                daysSection
                selectorSection(title: t("onboarding.equipment"), selection: $equipment, labelKey: { "onboarding.equipment.\($0.rawValue)" })

                if showError {
                    Text(t("onboarding.error.range"))
                        .font(.footnote)
                        .foregroundStyle(Theme.danger)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                generateButton
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
        .background(Theme.background)
        .onAppear {
            withAnimation(Theme.springAnimation.delay(0.1)) { appear = true }
        }
    }

    private var measurementsSection: some View {
        VStack(spacing: 14) {
            fieldRow(title: t("onboarding.weight"), text: $weightText, suffix: "kg")
            fieldRow(title: t("onboarding.height"), text: $heightText, suffix: "cm")
            fieldRow(title: t("onboarding.age"), text: $ageText, suffix: "")
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
    }

    private func fieldRow(title: String, text: Binding<String>, suffix: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Theme.textDim)
            Spacer()
            TextField("", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Theme.text)
                .frame(width: 80)
            if !suffix.isEmpty {
                Text(suffix)
                    .foregroundStyle(Theme.textFaint)
                    .font(.caption)
            }
        }
        .padding(16)
        .panelBackground()
    }

    private var daysSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(t("onboarding.days"))
                .foregroundStyle(Theme.textDim)
                .font(.subheadline)
            HStack(spacing: 10) {
                ForEach(3...6, id: \.self) { day in
                    Button {
                        withAnimation(Theme.springAnimation) { daysPerWeek = day }
                    } label: {
                        Text("\(day)")
                            .font(.headline)
                            .frame(width: 44, height: 44)
                            .foregroundStyle(daysPerWeek == day ? Color.black : Theme.text)
                            .background(
                                Circle().fill(daysPerWeek == day ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.panel))
                            )
                            .scaleEffect(daysPerWeek == day ? 1.08 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .opacity(appear ? 1 : 0)
    }

    private func selectorSection<T: Identifiable & Hashable>(title: String, selection: Binding<T>, labelKey: @escaping (T) -> String) -> some View where T: CaseIterable, T.AllCases == [T] {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .foregroundStyle(Theme.textDim)
                .font(.subheadline)
            VStack(spacing: 8) {
                ForEach(T.allCases) { option in
                    OptionRow(
                        label: t(labelKey(option)),
                        isSelected: selection.wrappedValue == option
                    ) {
                        withAnimation(Theme.springAnimation) { selection.wrappedValue = option }
                    }
                }
            }
        }
        .opacity(appear ? 1 : 0)
    }

    private var generateButton: some View {
        Button {
            generate()
        } label: {
            Text(t("onboarding.generate"))
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .shadow(color: Theme.accent.opacity(0.35), radius: 14, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
        .opacity(appear ? 1 : 0)
    }

    private func generate() {
        guard
            let weight = Double(weightText.replacingOccurrences(of: ",", with: ".")),
            let height = Double(heightText.replacingOccurrences(of: ",", with: ".")),
            let age = Int(ageText)
        else {
            withAnimation { showError = true }
            return
        }

        let profile = UserProfile(
            weightKg: weight, heightCm: height, age: age, sex: sex,
            level: level, goal: goal, daysPerWeek: daysPerWeek, equipment: equipment
        )

        guard profile.isValid else {
            withAnimation { showError = true }
            return
        }

        withAnimation { showError = false }
        viewModel.save(profile: profile)
    }
}

private struct OptionRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .foregroundStyle(isSelected ? Theme.text : Theme.textDim)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Theme.panel2 : Theme.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Theme.accent.opacity(0.6) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
