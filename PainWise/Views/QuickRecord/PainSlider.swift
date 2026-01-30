import SwiftUI

struct PainSlider: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var thumbSize: CGFloat = 32
    @Binding var value: Double

    private var adjustedThumbSize: CGFloat {
        min(thumbSize, 48)  // Cap maximum size for usability
    }

    var body: some View {
        VStack(spacing: 8) {
            // Custom Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorScheme == .dark ? Color(hex: "234836") : Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Filled Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary, painLevelColor(for: Int(value))],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(value / 10) * geometry.size.width, height: 8)

                    // Thumb (with Dynamic Type scaling)
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: adjustedThumbSize, height: adjustedThumbSize)
                        .shadow(color: Color.appPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .offset(x: CGFloat(value / 10) * (geometry.size.width - adjustedThumbSize))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    let newValue = gesture.location.x / geometry.size.width * 10
                                    value = min(max(0, newValue), 10)
                                }
                        )
                }
                .frame(height: 48)
            }
            .frame(height: 48)

            // Labels
            HStack {
                Text("なし (None)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gray)

                Spacer()

                Text("激痛 (Severe)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gray)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "accessibility_pain_level_slider"))
        .accessibilityValue(String(localized: "accessibility_pain_level_value \(Int(value))"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(10, value + 1)
            case .decrement:
                value = max(0, value - 1)
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Numeric Scale Slider (Alternative)
struct NumericPainSlider: View {
    @Environment(\.colorScheme) var colorScheme
    @ScaledMetric(relativeTo: .body) private var buttonPadding: CGFloat = 8
    @Binding var value: Int

    var body: some View {
        VStack(spacing: 16) {
            // Number Scale
            HStack(spacing: 0) {
                ForEach(0...10, id: \.self) { level in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            value = level
                        }
                    } label: {
                        Text("\(level)")
                            .font(.system(size: level == value ? 18 : 14, weight: level == value ? .bold : .medium))
                            .foregroundStyle(level == value ? Color.appPrimary : Color.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, buttonPadding)
                            .background(
                                level == value ?
                                    Color.appPrimary.opacity(0.1) :
                                    Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Color Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Gradient Background
                    LinearGradient(
                        colors: [
                            Color.green,
                            Color.yellow,
                            Color.orange,
                            Color.red
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 6)
                    .clipShape(Capsule())
                    .opacity(0.3)

                    // Progress
                    LinearGradient(
                        colors: [
                            Color.green,
                            painLevelColor(for: value)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: CGFloat(value) / 10 * geometry.size.width, height: 6)
                    .clipShape(Capsule())

                    // Indicator
                    Circle()
                        .fill(painLevelColor(for: value))
                        .frame(width: 16, height: 16)
                        .shadow(color: painLevelColor(for: value).opacity(0.5), radius: 4)
                        .offset(x: CGFloat(value) / 10 * (geometry.size.width - 16))
                }
            }
            .frame(height: 16)
        }
        // Accessibility
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "accessibility_pain_level_slider"))
        .accessibilityValue(String(localized: "accessibility_pain_level_value \(value)"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(10, value + 1)
            case .decrement:
                value = max(0, value - 1)
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        PainSlider(value: .constant(5))

        NumericPainSlider(value: .constant(7))
    }
    .padding()
    .background(Color.backgroundDark)
    .preferredColorScheme(.dark)
}
