import SwiftUI

struct SplashView: View {
    @State private var pulse = false
    @State private var appear = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 96, height: 96)
                    .opacity(0.18)
                    .scaleEffect(pulse ? 1.25 : 0.9)
                    .blur(radius: 10)

                Image(systemName: "figure.strengthtraining.functional")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(Theme.accentGradient)
                    .scaleEffect(appear ? 1 : 0.6)
                    .opacity(appear ? 1 : 0)
            }
            .frame(height: 110)

            Text(t("app.name"))
                .font(.title2.bold())
                .foregroundStyle(Theme.text)
                .opacity(appear ? 1 : 0)

            Text(t("app.tagline"))
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
                .opacity(appear ? 1 : 0)

            Spacer().frame(height: 30)

            VStack(spacing: 4) {
                Text(t("about.developedBy"))
                    .font(.caption)
                    .foregroundStyle(Theme.textFaint)
                Text("ividi.dev")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.accent)
            }
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
