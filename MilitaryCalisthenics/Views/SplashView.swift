import SwiftUI

struct SplashView: View {
    let theme = Theme.shared
    @State private var pulse = false
    @State private var appear = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(theme.accentGradient)
                    .frame(width: 96, height: 96)
                    .opacity(0.18)
                    .scaleEffect(pulse ? 1.25 : 0.9)
                    .blur(radius: 10)

                VStack(spacing: 2) {
                    // Single rank chevron, matching the app icon's mark.
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(theme.accent)
                        .offset(y: appear ? 0 : -6)
                        .opacity(appear ? 1 : 0)

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(theme.accentGradient)
                }
                .scaleEffect(appear ? 1 : 0.6)
                .opacity(appear ? 1 : 0)
            }
            .frame(height: 110)

            Text(t("app.name"))
                .font(.title2.bold())
                .foregroundStyle(theme.text)
                .opacity(appear ? 1 : 0)

            Text(t("app.tagline"))
                .font(.subheadline)
                .foregroundStyle(theme.textDim)
                .opacity(appear ? 1 : 0)

            Spacer().frame(height: 30)

            VStack(spacing: 4) {
                Text(t("about.developedBy"))
                    .font(.caption)
                    .foregroundStyle(theme.textFaint)
                Text("ividi.dev")
                    .font(.caption.bold())
                    .foregroundStyle(theme.accent)
            }
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
