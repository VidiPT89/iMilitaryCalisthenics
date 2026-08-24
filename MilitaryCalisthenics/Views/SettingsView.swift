import SwiftUI

struct SettingsView: View {
    var viewModel: PlanViewModel
    @State private var lang = LocalizationManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(t("settings.title"))
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.text)
                    .padding(.top, 24)

                languageCard
                editProfileButton
                aboutCard
            }
            .padding(20)
        }
        .background(Theme.background)
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
