import SwiftUI

enum Tab: CaseIterable {
    case home
    case history
    case analysis
    case forecast
    case settings

    var localizedName: String {
        switch self {
        case .home: return L10n.tabHome
        case .history: return L10n.tabHistory
        case .analysis: return L10n.tabAnalysis
        case .forecast: return L10n.tabForecast
        case .settings: return L10n.tabSettings
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .history: return "clock.arrow.circlepath"
        case .analysis: return "chart.bar.xaxis"
        case .forecast: return "sparkles"
        case .settings: return "gearshape.fill"
        }
    }

    var iconOutline: String {
        switch self {
        case .home: return "house"
        case .history: return "clock.arrow.circlepath"
        case .analysis: return "chart.bar.xaxis"
        case .forecast: return "sparkles"
        case .settings: return "gearshape"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            (colorScheme == .dark ? Color.surfaceDark.opacity(0.95) : Color.white.opacity(0.95))
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.2))
                .frame(height: 1),
            alignment: .top
        )
    }
}

struct TabBarButton: View {
    let tab: Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.icon : tab.iconOutline)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? Color.appPrimary : Color.gray)

                Text(tab.localizedName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? Color.appPrimary : Color.gray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBar(selectedTab: .constant(.home))
    }
    .background(Color.backgroundDark)
    .preferredColorScheme(.dark)
}
