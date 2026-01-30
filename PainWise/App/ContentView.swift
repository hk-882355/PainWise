import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            mainContent
        } else {
            OnboardingView()
        }
    }

    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            Group {
                switch selectedTab {
                case .home:
                    DashboardView()
                case .history:
                    HistoryView()
                case .analysis:
                    AnalysisView()
                case .forecast:
                    ForecastView()
                case .settings:
                    SettingsView()
                }
            }

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .modelContainer(for: PainRecord.self, inMemory: true)
}
