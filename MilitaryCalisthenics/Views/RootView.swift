import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemColorScheme
    let theme = Theme.shared
    @State private var viewModel = PlanViewModel()

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if !viewModel.hasLoaded && viewModel.storageErrorKey == nil {
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
            } else if !viewModel.hasLoaded {
                StorageUnavailableView { viewModel.load(context: modelContext) }
            } else if viewModel.profile == nil {
                OnboardingView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                MainTabView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(theme.mode == .system ? nil : (theme.mode == .dark ? .dark : .light))
        .onAppear {
            viewModel.load(context: modelContext)
            theme.systemIsDark = systemColorScheme == .dark
        }
        .onChange(of: viewModel.profile?.daysPerWeek) { _, days in
            if let days { Task { await ReminderManager.shared.reschedule(daysPerWeek: days) } }
        }
        .onChange(of: LocalizationManager.shared.current) { _, _ in
            if let days = viewModel.profile?.daysPerWeek {
                Task { await ReminderManager.shared.reschedule(daysPerWeek: days) }
            }
        }
        .onChange(of: systemColorScheme) { _, newValue in
            theme.systemIsDark = newValue == .dark
        }
    }
}
