import SwiftUI
import StoreKit

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @ObservedObject private var storeKit = StoreKitManager.shared
    @AppStorage("selectedTab") private var selectedTabRaw = Tab.home.rawValue

    @State private var selectedProduct: Product?
    @State private var showError = false
    @State private var isPurchasing = false
    @State private var showUnlockedSheet = false
    @State private var wasPremium = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Features
                    featuresSection

                    if storeKit.isPremium {
                        premiumActiveSection
                    } else {
                        // Products
                        productsSection

                        // Purchase Button
                        purchaseButton

                        // Restore
                        restoreButton
                    }

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
        .onAppear {
            wasPremium = storeKit.isPremium
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
        .onChange(of: storeKit.isPremium) { _, newValue in
            if newValue && !wasPremium {
                showUnlockedSheet = true
            }
            wasPremium = newValue
        }
        .sheet(isPresented: $showUnlockedSheet) {
            PremiumUnlockedSheet(
                onSelectTab: { tab in
                    selectedTabRaw = tab.rawValue
                    showUnlockedSheet = false
                    dismiss()
                },
                onClose: {
                    showUnlockedSheet = false
                    dismiss()
                }
            )
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
                title: "5日間の天気予報",
                description: "より長期の痛み予測が可能に"
            )

            FeatureRow(
                icon: "doc.text.magnifyingglass",
                title: "分析レポート",
                description: "痛みの相関や傾向を確認"
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
                        showUnlockedSheet = true
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
        .disabled(storeKit.isPremium || selectedProduct == nil || isPurchasing)
    }

    // MARK: - Restore Button
    private var restoreButton: some View {
        Button("購入を復元") {
            Task {
                await storeKit.restorePurchases()
                if storeKit.isPremium {
                    showUnlockedSheet = true
                }
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    // MARK: - Premium Active
    private var premiumActiveSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color.appPrimary)
                Text("プレミアムは有効です")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Button("サブスクリプションを管理") {
                guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
                openURL(url)
            }
            .font(.subheadline)
            .foregroundStyle(Color.appPrimary)

            restoreButton
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.cardDark : Color.cardLight)
        )
    }

    // MARK: - Legal Links
    private var legalLinks: some View {
        HStack(spacing: 16) {
            if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                Link(destination: url) {
                    Text("利用規約")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("•")
                .foregroundStyle(.secondary)

            if let url = URL(string: "https://hk-882355.github.io/painwise-privacy/") {
                Link(destination: url) {
                    Text("プライバシーポリシー")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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

// MARK: - Premium Unlocked Sheet
struct PremiumUnlockedSheet: View {
    let onSelectTab: (Tab) -> Void
    let onClose: () -> Void

    private let shortcuts: [(title: String, subtitle: String, tab: Tab)] = [
        ("5日間の天気予報", "予報タブで確認", .forecast),
        ("分析サマリー", "分析タブで確認", .analysis),
        ("PDFエクスポート", "履歴タブで出力", .history),
        ("HealthKit連携", "設定で有効化", .settings)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.appPrimary)

                    Text("プレミアムが有効になりました")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("使えるようになった機能はこちらです")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                VStack(spacing: 8) {
                    ForEach(shortcuts, id: \.title) { item in
                        Button {
                            onSelectTab(item.tab)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Text(item.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(14)
                            .background(Color.surfaceHighlight.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button("あとで") {
                    onClose()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("プレミアム解放")
            .navigationBarTitleDisplayMode(.inline)
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

    private var perMonthPriceText: String? {
        guard product.id == ProductID.yearlyPremium.rawValue,
              let subscription = product.subscription else {
            return nil
        }

        let months: Int
        switch subscription.subscriptionPeriod.unit {
        case .year:
            months = subscription.subscriptionPeriod.value * 12
        case .month:
            months = subscription.subscriptionPeriod.value
        default:
            return nil
        }

        guard months > 0 else { return nil }
        let total = NSDecimalNumber(decimal: product.price)
        let perMonth = total.dividing(by: NSDecimalNumber(value: months)).decimalValue
        return "\(formatPrice(perMonth)) /月 相当"
    }

    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "\(price)"
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

                    if let perMonthPriceText {
                        Text(perMonthPriceText)
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
