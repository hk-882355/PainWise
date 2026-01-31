import SwiftUI

struct ForecastCard: View {
    @Environment(\.colorScheme) var colorScheme

    let alertLevel: AlertLevel
    let pressure: Int
    let message: String
    let accuracy: Int
    var onViewDetail: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.appPrimary)

                        Text(L10n.forecastCardTodayPrediction)
                            .font(.headline)
                            .fontWeight(.bold)
                    }

                    Text(L10n.forecastCardAiAnalysis)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                // Accuracy Badge
                Text("\(L10n.forecastCardAccuracy) \(accuracy)%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.surfaceHighlight.opacity(0.5))
                    .clipShape(Capsule())
            }

            // Content Row
            HStack(alignment: .top, spacing: 16) {
                // Alert Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(alertLevel.color)

                        Text("\(L10n.forecastCardAlert): \(alertLevel.text)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? Color.gray.opacity(0.9) : Color.gray.opacity(0.8))
                        .lineSpacing(4)
                }

                Spacer()

                // Weather Widget
                VStack(spacing: 4) {
                    Image(systemName: "cloud.rain.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.textSecondary)

                    Text("\(pressure) hPa")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .frame(width: 80)
                .padding(.vertical, 8)
                .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Footer
            Divider()
                .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2))

            HStack {
                Spacer()

                Button(action: { onViewDetail?() }) {
                    HStack(spacing: 4) {
                        Text(L10n.forecastCardViewDetail)
                            .font(.caption)
                            .fontWeight(.bold)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.appPrimary)
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                // Gradient Background - supports light/dark mode
                LinearGradient(
                    colors: colorScheme == .dark ? [
                        Color(hex: "193326"),
                        Color(hex: "102a1f")
                    ] : [
                        Color(hex: "e8f5e9"),
                        Color(hex: "c8e6c9")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Decorative Glow
                Circle()
                    .fill(Color.appPrimary.opacity(0.05))
                    .frame(width: 160, height: 160)
                    .blur(radius: 40)
                    .offset(x: 80, y: -40)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appPrimary.opacity(0.1), lineWidth: 1)
        )
        // Accessibility
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "accessibility_forecast_card_label"))
        .accessibilityValue(String(localized: "accessibility_forecast_card_value \(alertLevel.text) \(pressure) \(accuracy)"))
        .accessibilityHint(String(localized: "accessibility_forecast_card_hint"))
    }
}

#Preview {
    ForecastCard(
        alertLevel: .medium,
        pressure: 1008,
        message: "低気圧が接近中です。\n午後から気圧の変化により、頭痛や関節痛が出やすくなる可能性があります。",
        accuracy: 87
    )
    .padding()
    .background(Color.backgroundDark)
    .preferredColorScheme(.dark)
}
