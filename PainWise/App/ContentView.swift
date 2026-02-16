import SwiftUI

struct ContentView: View {
    @AppStorage("selectedTab") private var selectedTabRaw = Tab.home.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true
    @State private var splashOpacity = 0.0
    @State private var hasShownSplash = false

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                mainContent
            } else {
                OnboardingView()
            }

            if showSplash {
                SplashView(opacity: splashOpacity)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            startSplashAnimation()
        }
    }

    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            Group {
                switch selectedTabBinding.wrappedValue {
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
            CustomTabBar(selectedTab: selectedTabBinding)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var selectedTabBinding: Binding<Tab> {
        Binding(
            get: { Tab(rawValue: selectedTabRaw) ?? .home },
            set: { selectedTabRaw = $0.rawValue }
        )
    }

    private func startSplashAnimation() {
        guard showSplash, !hasShownSplash else { return }
        hasShownSplash = true
        withAnimation(.easeOut(duration: 0.4)) {
            splashOpacity = 1.0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.7))
            withAnimation(.easeIn(duration: 0.4)) {
                splashOpacity = 0.0
            }
            try? await Task.sleep(for: .seconds(0.45))
            showSplash = false
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .modelContainer(for: PainRecord.self, inMemory: true)
}

private struct SplashView: View {
    let opacity: Double

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
            Text("PainWise")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color.primary)
                .opacity(opacity)
        }
        .accessibilityHidden(true)
    }
}
