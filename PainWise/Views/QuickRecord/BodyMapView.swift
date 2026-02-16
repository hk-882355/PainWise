import SwiftUI

struct BodyMapView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var showFront: Bool
    @Binding var selectedParts: Set<BodyPart>

    @State private var showingTooltip: BodyPart?

    // Body part positions (relative to container)
    private let frontBodyParts: [BodyPart: CGPoint] = [
        .head: CGPoint(x: 0.5, y: 0.08),
        .neck: CGPoint(x: 0.5, y: 0.16),
        .leftShoulder: CGPoint(x: 0.3, y: 0.22),
        .rightShoulder: CGPoint(x: 0.7, y: 0.22),
        .chest: CGPoint(x: 0.5, y: 0.28),
        .leftArm: CGPoint(x: 0.2, y: 0.35),
        .rightArm: CGPoint(x: 0.8, y: 0.35),
        .abdomen: CGPoint(x: 0.5, y: 0.38),
        .lowerBack: CGPoint(x: 0.5, y: 0.46),  // Added for front view (important for chronic pain users)
        .leftHand: CGPoint(x: 0.15, y: 0.50),
        .rightHand: CGPoint(x: 0.85, y: 0.50),
        .leftHip: CGPoint(x: 0.35, y: 0.54),
        .rightHip: CGPoint(x: 0.65, y: 0.54),
        .leftLeg: CGPoint(x: 0.38, y: 0.62),
        .rightLeg: CGPoint(x: 0.62, y: 0.62),
        .leftKnee: CGPoint(x: 0.38, y: 0.72),
        .rightKnee: CGPoint(x: 0.62, y: 0.72),
        .leftFoot: CGPoint(x: 0.38, y: 0.88),
        .rightFoot: CGPoint(x: 0.62, y: 0.88)
    ]

    private let backBodyParts: [BodyPart: CGPoint] = [
        .head: CGPoint(x: 0.5, y: 0.08),
        .neck: CGPoint(x: 0.5, y: 0.16),
        .leftShoulder: CGPoint(x: 0.7, y: 0.22),  // Mirrored
        .rightShoulder: CGPoint(x: 0.3, y: 0.22), // Mirrored
        .upperBack: CGPoint(x: 0.5, y: 0.30),
        .lowerBack: CGPoint(x: 0.5, y: 0.42),
        .leftArm: CGPoint(x: 0.8, y: 0.35),
        .rightArm: CGPoint(x: 0.2, y: 0.35),
        .leftHand: CGPoint(x: 0.85, y: 0.50),
        .rightHand: CGPoint(x: 0.15, y: 0.50),
        .leftHip: CGPoint(x: 0.65, y: 0.52),
        .rightHip: CGPoint(x: 0.35, y: 0.52),
        .leftLeg: CGPoint(x: 0.62, y: 0.60),
        .rightLeg: CGPoint(x: 0.38, y: 0.60),
        .leftKnee: CGPoint(x: 0.62, y: 0.70),
        .rightKnee: CGPoint(x: 0.38, y: 0.70),
        .leftFoot: CGPoint(x: 0.62, y: 0.88),
        .rightFoot: CGPoint(x: 0.38, y: 0.88)
    ]

    var body: some View {
        GeometryReader { geometry in
            let bodyWidth = geometry.size.width * 0.6
            let bodyHeight = geometry.size.height * 0.9
            let bodyOffsetX = (geometry.size.width - bodyWidth) / 2
            let bodyOffsetY = (geometry.size.height - bodyHeight) / 2

            ZStack {
                // Body Silhouette
                bodyOutline
                    .frame(width: bodyWidth, height: bodyHeight)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                // Touch Points
                let parts = showFront ? frontBodyParts : backBodyParts
                ForEach(Array(parts.keys), id: \.self) { part in
                    if let position = parts[part] {
                        bodyPartButton(
                            part: part,
                            position: CGPoint(
                                x: bodyOffsetX + bodyWidth * position.x,
                                y: bodyOffsetY + bodyHeight * position.y
                            ),
                            isSelected: selectedParts.contains(part)
                        )
                    }
                }

                // Tooltip
                if let tooltipPart = showingTooltip,
                   let position = (showFront ? frontBodyParts : backBodyParts)[tooltipPart] {
                    tooltipView(for: tooltipPart)
                        .position(
                            x: bodyOffsetX + bodyWidth * position.x + 60,
                            y: bodyOffsetY + bodyHeight * position.y
                        )
                }
            }
        }
    }

    // MARK: - Body Outline
    private var bodyOutline: some View {
        ZStack {
            // Simple body shape using SF Symbol
            Image(systemName: "figure.stand")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.15) : Color.gray.opacity(0.2))

            // Outer glow ring for selected area
            if !selectedParts.isEmpty {
                Circle()
                    .stroke(Color.appPrimary.opacity(0.3), lineWidth: 2)
                    .frame(width: 200, height: 200)
                    .blur(radius: 10)
            }
        }
    }

    // MARK: - Body Part Button
    private func bodyPartButton(part: BodyPart, position: CGPoint, isSelected: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedParts.contains(part) {
                    selectedParts.remove(part)
                    showingTooltip = nil
                } else {
                    selectedParts.insert(part)
                    showingTooltip = part

                    // Hide tooltip after delay
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(2))
                        if showingTooltip == part {
                            withAnimation {
                                showingTooltip = nil
                            }
                        }
                    }
                }
            }
        } label: {
            ZStack {
                // Pulse animation for selected
                if isSelected {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Circle()
                        .stroke(Color.appPrimary, lineWidth: 2)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.appPrimary.opacity(0.4), radius: 8)
                }

                // Center dot
                Circle()
                    .fill(isSelected ? Color.appPrimary : Color.clear)
                    .frame(width: 16, height: 16)

                // Hover area (enlarged for better accessibility)
                Circle()
                    .fill(Color.clear)
                    .frame(width: 60, height: 60)
                    .contentShape(Circle())
            }
        }
        .buttonStyle(.plain)
        .position(position)
        .accessibilityLabel(part.localizedName)
        .accessibilityHint(isSelected ? String(localized: "accessibility_tap_to_deselect") : String(localized: "accessibility_tap_to_select"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Tooltip
    private func tooltipView(for part: BodyPart) -> some View {
        Text("\(part.rawValue) (\(part.englishName))")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "11221a"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(colorScheme == .dark ? Color(hex: "2f5e48") : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.2), radius: 8)
    }
}

#Preview {
    VStack {
        BodyMapView(
            showFront: .constant(true),
            selectedParts: .constant([.lowerBack])
        )
        .frame(height: 400)
    }
    .padding()
    .background(Color.backgroundDark)
    .preferredColorScheme(.dark)
}
