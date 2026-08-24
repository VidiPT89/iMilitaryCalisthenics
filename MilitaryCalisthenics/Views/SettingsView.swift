import SwiftUI

struct SettingsView: View {
    var viewModel: PlanViewModel
    @State private var lang = LocalizationManager.shared
    @State private var reminders = ReminderManager.shared
    @State private var showProgress = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(t("settings.title"))
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.text)
                    .padding(.top, 24)

                languageCard
                progressButton
                remindersCard
                regeneratePlanButton
                editProfileButton
                aboutCard
            }
            .padding(20)
        }
        .background(Theme.background)
        .sheet(isPresented: $showProgress) {
            WeightProgressView(viewModel: viewModel)
        }
    }

    private var progressButton: some View {
        Button {
            showProgress = true
        } label: {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text(t("settings.progress"))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.textFaint)
            }
            .foregroundStyle(Theme.text)
            .padding(16)
            .panelBackground()
        }
        .buttonStyle(.plain)
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("settings.language"))
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)

            HStack(spacing: 10) {
                ForEach(Lang.allCases, id: \.self) { option in
                    let isSelected = lang.current == option
                    Button {
                        withAnimation(Theme.springAnimation) { lang.current = option }
                    } label: {
                        Text(option == .pt ? "PT-PT" : "EN")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(isSelected ? Color.black : Theme.textDim)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.panel2))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .panelBackground()
    }

    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(t("reminders.title"))
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { reminders.isEnabled },
                    set: { newValue in
                        reminders.isEnabled = newValue
                        Task {
                            if newValue {
                                let granted = await reminders.requestAuthorizationAndSchedule(
                                    daysPerWeek: viewModel.profile?.daysPerWeek ?? 4
                                )
                                if !granted { reminders.isEnabled = false }
                            } else {
                                reminders.disable()
                            }
                        }
                    }
                ))
                .tint(Theme.accent)
                .labelsHidden()
            }

            if reminders.permissionDenied && !reminders.isEnabled {
                Text(t("reminders.denied"))
                    .font(.caption)
                    .foregroundStyle(Theme.danger)
            }

            if reminders.isEnabled {
                DatePicker(
                    t("reminders.time"),
                    selection: Binding(
                        get: {
                            Calendar.current.date(
                                bySettingHour: reminders.hour, minute: reminders.minute, second: 0, of: Date()
                            ) ?? Date()
                        },
                        set: { newDate in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            reminders.hour = comps.hour ?? 18
                            reminders.minute = comps.minute ?? 0
                            Task { await reminders.reschedule(daysPerWeek: viewModel.profile?.daysPerWeek ?? 4) }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .foregroundStyle(Theme.text)
                .datePickerStyle(.compact)
                .tint(Theme.accent)
            }
        }
        .padding(16)
        .panelBackground()
    }

    private var regeneratePlanButton: some View {
        Button {
            withAnimation(Theme.springAnimation) { viewModel.regeneratePlan() }
        } label: {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text(t("settings.regeneratePlan"))
                Spacer()
            }
            .foregroundStyle(Theme.text)
            .padding(16)
            .panelBackground()
        }
        .buttonStyle(.plain)
        .disabled(viewModel.profile == nil)
    }

    private var editProfileButton: some View {
        Button {
            withAnimation(Theme.springAnimation) { viewModel.profile = nil }
        } label: {
            HStack {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                Text(t("plan.regenerate"))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.textFaint)
            }
            .foregroundStyle(Theme.text)
            .padding(16)
            .panelBackground()
        }
        .buttonStyle(.plain)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t("settings.about"))
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)

            VStack(alignment: .leading, spacing: 10) {
                Text(t("about.developedBy"))
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Link(destination: URL(string: "https://ividi.dev/")!) {
                    Label("ividi.dev", systemImage: "globe")
                        .foregroundStyle(Theme.accent)
                }

                Link(destination: URL(string: "https://github.com/VidiPT89/")!) {
                    Label("github.com/VidiPT89", systemImage: "chevron.left.slash.chevron.right")
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .padding(16)
        .panelBackground()
    }
}
