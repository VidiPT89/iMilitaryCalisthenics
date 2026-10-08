import SwiftUI
import SwiftData

@main
struct MilitaryCalisthenicsApp: App {
    @State private var modelContainer: ModelContainer? = Self.openStore()

    private static func openStore() -> ModelContainer? {
        // Do not replace or delete an unreadable database.
        try? ModelContainer(for: PersistedProfile.self, WeightEntry.self)
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer {
                RootView().modelContainer(modelContainer)
            } else {
                StorageUnavailableView { modelContainer = Self.openStore() }
            }
        }
    }
}

struct StorageUnavailableView: View {
    let retry: () -> Void
    private let theme = Theme.shared

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.largeTitle)
            Text(t("storage.title")).font(.title2.bold())
            Text(t("storage.readError")).multilineTextAlignment(.center)
            Button(t("storage.retry"), action: retry).buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(theme.text)
        .background(theme.background)
        .tint(theme.accent)
    }
}
