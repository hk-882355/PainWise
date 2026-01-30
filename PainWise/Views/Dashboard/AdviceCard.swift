import SwiftUI

struct AdviceCard: View {
    @Environment(\.colorScheme) var colorScheme

    let category: String
    let title: String
    let description: String
    let imageName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Area
            ZStack {
                // Gradient Background
                LinearGradient(
                    colors: [
                        Color.appPrimary.opacity(0.3),
                        Color.appPrimary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: imageName)
                    .font(.system(size: 48))
                    .foregroundStyle(Color.appPrimary.opacity(0.5))
            }
            .frame(height: 128)

            // Text Content
            VStack(alignment: .leading, spacing: 8) {
                Text(category.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.appPrimary)
                    .tracking(1)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(2)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
            }
            .padding(12)
        }
        .frame(width: 256)
        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    HStack(spacing: 16) {
        AdviceCard(
            category: "リラックス",
            title: "自律神経を整えるお茶の選び方",
            description: "カフェインレスのハーブティーがおすすめです。特にカモミールは...",
            imageName: "cup.and.saucer.fill"
        )

        AdviceCard(
            category: "運動",
            title: "痛みが少ない日の軽いストレッチ",
            description: "無理のない範囲で体を動かすことで血流を改善しましょう。",
            imageName: "figure.flexibility"
        )
    }
    .padding()
    .background(Color.backgroundDark)
    .preferredColorScheme(.dark)
}
