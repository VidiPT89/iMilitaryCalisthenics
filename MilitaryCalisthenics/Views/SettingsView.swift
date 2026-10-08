import SwiftUI

struct SettingsView: View {
    var viewModel: PlanViewModel
    @State private var theme = Theme.shared
    @State private var lang = LocalizationManager.shared
    @State private var reminders = ReminderManager.shared
    @State private var showProgress = false
    @State private var showProfileEditor = false
    @State private var confirmRestart = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(t("settings.title"))
                    .font(.largeTitle.bold())
                    .foregroundStyle(theme.text)
                    .padding(.top, 24)

                appearanceCard
                languageCard
                progressButton
                remindersCard
                regeneratePlanButton
                editProfileButton
                aboutCard
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(theme.background)
        .alert(t("storage.title"), isPresented: Binding(
            get: { !showProfileEditor && !showProgress && viewModel.storageErrorKey != nil },
            set: { if !$0 { viewModel.storageErrorKey = nil } }
        )) {
            Button(t("common.close")) { viewModel.storageErrorKey = nil }
        } message: { Text(t(viewModel.storageErrorKey ?? "storage.saveError")) }
        .alert(t("settings.regeneratePlan"), isPresented: $confirmRestart) {
            Button(t("common.cancel"), role: .cancel) { }
            Button(t("settings.regeneratePlan"), role: .destructive) { viewModel.regeneratePlan() }
        } message: { Text(t("profile.restartWarning")) }
        .sheet(isPresented: $showProfileEditor) {
            NavigationStack {
                OnboardingView(viewModel: viewModel, initialProfile: viewModel.profile) {
                    showProfileEditor = false
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(t("common.cancel")) { showProfileEditor = false }
                    }
                }
            }
        }
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
                    .foregroundStyle(theme.textFaint)
            }
            .foregroundStyle(theme.text)
            .padding(16)
            .panelBackground()
        }
        .buttonStyle(.plain)
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("settings.appearance"))
                .font(.subheadline)
                .foregroundStyle(theme.textDim)

            HStack(spacing: 10) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    let isSelected = theme.mode == mode
                    Button {
                        withAnimation(theme.springAnimation) { theme.mode = mode }
                    } label: {
                        Text(t("settings.appearance.\(mode.rawValue)"))
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(isSelected ? Color.black : theme.textDim)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? AnyShapeStyle(theme.buttonGradient) : AnyShapeStyle(theme.panel2))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .panelBackground()
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("settings.language"))
                .font(.subheadline)
                .foregroundStyle(theme.textDim)

            HStack(spacing: 10) {
                ForEach(Lang.allCases, id: \.self) { option in
                    let isSelected = lang.current == option
                    Button {
                        withAnimation(theme.springAnimation) { lang.current = option }
                    } label: {
                        Text(option == .pt ? "PT-PT" : "EN")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(isSelected ? Color.black : theme.textDim)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? AnyShapeStyle(theme.buttonGradient) : AnyShapeStyle(theme.panel2))
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
                    .foregroundStyle(theme.textDim)
                Spacer()
                Toggle(t("reminders.title"), isOn: Binding(
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
                .tint(theme.accent)
                .labelsHidden()
            }

            if reminders.permissionDenied && !reminders.isEnabled {
                Text(t("reminders.denied"))
                    .font(.caption)
                    .foregroundStyle(theme.danger)
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
                .foregroundStyle(theme.text)
                .datePickerStyle(.compact)
                .tint(theme.accent)
            }
        }
        .padding(16)
        .panelBackground()
    }

    private var regeneratePlanButton: some View {
        Button {
            confirmRestart = true
        } label: {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text(t("settings.regeneratePlan"))
                Spacer()
            }
            .foregroundStyle(theme.text)
            .padding(16)
            .panelBackground()
        }
        .buttonStyle(.plain)
        .disabled(viewModel.profile == nil)
    }

    private var editProfileButton: some View {
        Button {
            showProfileEditor = true
        } label: {
            HStack {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                Text(t("plan.regenerate"))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(theme.textFaint)
            }
            .foregroundStyle(theme.text)
            .padding(16)
            .panelBackground()
        }
        .buttonStyle(.plain)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t("settings.about"))
                .font(.subheadline)
                .foregroundStyle(theme.textDim)

            VStack(alignment: .leading, spacing: 10) {
                Text(t("about.developedBy"))
                    .font(.headline)
                    .foregroundStyle(theme.text)

                Link(destination: URL(string: "https://ividi.dev/")!) {
                    Label("ividi.dev", systemImage: "globe")
                        .foregroundStyle(theme.accent)
                }

                Link(destination: URL(string: "https://github.com/VidiPT89/")!) {
                    Label("github.com/VidiPT89", systemImage: "chevron.left.slash.chevron.right")
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .padding(16)
        .panelBackground()
    }
}
