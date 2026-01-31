import SwiftUI
import StoreKit

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var storeKit = StoreKitManager.shared

    @State private var selectedProduct: Product?
    @State private var showError = false
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Features
                    featuresSection

                    // Products
                    productsSection

                    // Purchase Button
                    purchaseButton

                    // Restore
                    restoreButton

                    // Legal Links
                    legalLinks

                    // Subscription Info
                    subscriptionInfo
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                            .font(.title2)
                    }
                }
            }
        }
        .task {
            if storeKit.products.isEmpty {
                await storeKit.loadProducts()
            }
            selectedProduct = storeKit.yearlyProduct ?? storeKit.monthlyProduct
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(storeKit.errorMessage ?? "不明なエラーが発生しました")
        }
        .onChange(of: storeKit.errorMessage) { _, newValue in
            if newValue != nil {
                showError = true
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appPrimary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            .padding(.top, 20)

            Text("プレミアム")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("すべての機能をアンロック")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Features
    private var featuresSection: some View {
        VStack(spacing: 16) {
            FeatureRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "7日間の天気予報",
                description: "より長期の痛み予測が可能に"
            )

            FeatureRow(
                icon: "doc.text.magnifyingglass",
                title: "詳細AI分析レポート",
                description: "痛みのパターンを深く理解"
            )

            FeatureRow(
                icon: "square.and.arrow.up",
                title: "PDFエクスポート",
                description: "医師との共有に便利"
            )

            FeatureRow(
                icon: "heart.text.square",
                title: "HealthKit連携",
                description: "睡眠・歩数・心拍数を自動取得"
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.cardDark : Color.cardLight)
        )
    }

    // MARK: - Products
    private var productsSection: some View {
        VStack(spacing: 12) {
            if storeKit.isLoading && storeKit.products.isEmpty {
                ProgressView()
                    .padding()
            } else {
                ForEach(storeKit.products, id: \.id) { product in
                    ProductCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        isBestValue: product.id == ProductID.yearlyPremium.rawValue
                    ) {
                        selectedProduct = product
                    }
                }
            }
        }
    }

    // MARK: - Purchase Button
    private var purchaseButton: some View {
        Button {
            Task {
                guard let product = selectedProduct else { return }
                isPurchasing = true
                do {
                    _ = try await storeKit.purchase(product)
                    if storeKit.isPremium {
                        dismiss()
                    }
                } catch {
                    // Error is handled by storeKit.errorMessage
                }
                isPurchasing = false
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("購入する")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appPrimary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedProduct == nil || isPurchasing)
    }

    // MARK: - Restore Button
    private var restoreButton: some View {
        Button("購入を復元") {
            Task {
                await storeKit.restorePurchases()
                if storeKit.isPremium {
                    dismiss()
                }
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    // MARK: - Legal Links
    private var legalLinks: some View {
        HStack(spacing: 16) {
            Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                Text("利用規約")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("•")
                .foregroundStyle(.secondary)

            Link(destination: URL(string: "https://hiroki-it.github.io/painwise-privacy/")!) {
                Text("プライバシーポリシー")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Subscription Info
    private var subscriptionInfo: some View {
        Text("サブスクリプションは自動更新されます。次回更新日の24時間前までにキャンセルしない限り、自動的に課金されます。購入後、設定アプリからサブスクリプションを管理できます。")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.appPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.appPrimary)
        }
    }
}

// MARK: - Product Card
struct ProductCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool
    let action: () -> Void

    // 日本語ローカライズ（StoreKitから取得できない場合のフォールバック）
    private var localizedName: String {
        switch product.id {
        case ProductID.monthlyPremium.rawValue:
            return "月額プレミアム"
        case ProductID.yearlyPremium.rawValue:
            return "年額プレミアム"
        default:
            return product.displayName
        }
    }

    private var localizedDescription: String {
        switch product.id {
        case ProductID.monthlyPremium.rawValue:
            return "すべての機能をアンロック"
        case ProductID.yearlyPremium.rawValue:
            return "年額プラン - 2ヶ月分お得"
        default:
            return product.description
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(localizedName)
                            .font(.headline)

                        if isBestValue {
                            Text("お得")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.appPrimary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }

                    Text(localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)

                    if product.id == ProductID.yearlyPremium.rawValue {
                        Text("¥483/月 相当")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.cardDark : Color.cardLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PremiumView()
        .preferredColorScheme(.dark)
}
