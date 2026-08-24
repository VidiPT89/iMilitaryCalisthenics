import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemColorScheme
    let theme = Theme.shared
    @State private var viewModel = PlanViewModel()
    @State private var showSplash = true
    @State private var lang = LocalizationManager.shared

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if showSplash {
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(theme.springAnimation) { showSplash = false }
            }
        }
        .onChange(of: systemColorScheme) { _, newValue in
            theme.systemIsDark = newValue == .dark
        }
    }
}
