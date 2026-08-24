import SwiftUI

struct MainTabView: View {
    var viewModel: PlanViewModel
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case 0: PlanDashboardView(viewModel: viewModel)
                        .transition(.opacity)
                default: SettingsView(viewModel: viewModel)
                        .transition(.opacity)
                }
            }
            .animation(Theme.springAnimation, value: selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
        }
        .background(Theme.background)
    }

    private var tabBar: some View {
        HStack {
            tabItem(index: 0, icon: "list.bullet.rectangle.fill", labelKey: "tab.plan")
            tabItem(index: 1, icon: "gearshape.fill", labelKey: "tab.settings")
        }
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(Theme.panel.ignoresSafeArea(edges: .bottom))
        .overlay(Rectangle().fill(Theme.accent.opacity(0.08)).frame(height: 1), alignment: .top)
    }

    private func tabItem(index: Int, icon: String, labelKey: String) -> some View {
        Button {
            withAnimation(Theme.springAnimation) { selectedTab = index }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(t(labelKey))
                    .font(.caption2)
            }
            .foregroundStyle(selectedTab == index ? Theme.accent : Theme.textFaint)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
