import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseCrashlytics

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct PainWiseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    private let modelContainer: ModelContainer?
    private let modelContainerError: Error?

    init() {
        let schema = Schema([
            PainRecord.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContainerError = nil
        } catch {
            modelContainer = nil
            modelContainerError = error
            Crashlytics.crashlytics().record(error: error)
        }
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer {
                ContentView()
                    .modelContainer(modelContainer)
            } else {
                ModelContainerErrorView(error: modelContainerError)
            }
        }
    }
}

private struct ModelContainerErrorView: View {
    let error: Error?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)

            Text("データの読み込みに失敗しました")
                .font(.headline)

            Text("アプリを再起動しても改善しない場合は、サポートにご連絡ください。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
    }
}
