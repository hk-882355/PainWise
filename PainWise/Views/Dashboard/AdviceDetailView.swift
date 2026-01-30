import SwiftUI

struct AdviceDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    let category: String
    let title: String
    let description: String
    let imageName: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero Image
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color.appPrimary.opacity(0.3),
                                Color.appPrimary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Image(systemName: imageName)
                            .font(.system(size: 80))
                            .foregroundStyle(Color.appPrimary.opacity(0.5))
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Category Badge
                    Text(category.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.appPrimary)
                        .tracking(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.appPrimary.opacity(0.1))
                        .clipShape(Capsule())

                    // Title
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)

                    // Description
                    Text(description)
                        .font(.body)
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.8))
                        .lineSpacing(8)

                    // Additional Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text(L10n.adviceDetailBenefits)
                            .font(.headline)
                            .fontWeight(.bold)

                        benefitRow(icon: "heart.fill", color: .red, text: L10n.adviceDetailBenefit1)
                        benefitRow(icon: "brain.head.profile", color: .purple, text: L10n.adviceDetailBenefit2)
                        benefitRow(icon: "figure.mind.and.body", color: .green, text: L10n.adviceDetailBenefit3)
                    }
                    .padding(.top, 16)

                    // Tips Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.adviceDetailTips)
                            .font(.headline)
                            .fontWeight(.bold)

                        Text(L10n.adviceDetailTipsContent)
                            .font(.subheadline)
                            .foregroundStyle(Color.gray)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(colorScheme == .dark ? Color.surfaceDark : Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                }
            }
        }
    }

    private func benefitRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .foregroundStyle(color)
            }

            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    AdviceDetailView(
        category: "リラックス",
        title: "自律神経を整えるお茶の選び方",
        description: "カフェインレスのハーブティーがおすすめです。特にカモミールは鎮静効果があり、ストレス軽減に役立ちます。就寝前に温かいお茶を飲むことで、リラックス効果を高めることができます。",
        imageName: "cup.and.saucer.fill"
    )
    .preferredColorScheme(.dark)
}
