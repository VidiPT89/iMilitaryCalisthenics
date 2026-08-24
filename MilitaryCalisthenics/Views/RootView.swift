import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PlanViewModel()
    @State private var showSplash = true
    @State private var lang = LocalizationManager.shared

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

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
        .onAppear {
            viewModel.load(context: modelContext)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(Theme.springAnimation) { showSplash = false }
            }
        }
    }
}
