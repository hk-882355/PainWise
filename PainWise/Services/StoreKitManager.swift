import Foundation
import StoreKit

// MARK: - Product IDs
enum ProductID: String, CaseIterable, Sendable {
    case monthlyPremium = "com.hk.painwise.premium.monthly"
    case yearlyPremium = "com.hk.painwise.premium.yearly"

    var displayName: String {
        switch self {
        case .monthlyPremium: return "月額プラン"
        case .yearlyPremium: return "年額プラン"
        }
    }
}

// MARK: - StoreKit Manager
@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var updateListenerTask: Task<Void, Error>?
    private var initTask: Task<Void, Never>?

    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }

    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthlyPremium.rawValue }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == ProductID.yearlyPremium.rawValue }
    }

    private init() {
        updateListenerTask = listenForTransactions()

        initTask = Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
        initTask?.cancel()
    }

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
        } catch {
            errorMessage = "製品の読み込みに失敗しました: \(error.localizedDescription)"
            #if DEBUG
            print("[StoreKit] Failed to load products: \(error)")
            #endif
        }

        isLoading = false
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try Self.checkVerified(verification)
                await updatePurchasedProducts()
                await transaction.finish()
                return transaction

            case .userCancelled:
                return nil

            case .pending:
                errorMessage = "購入処理が保留中です"
                return nil

            @unknown default:
                return nil
            }
        } catch {
            errorMessage = "購入に失敗しました: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            errorMessage = "復元に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - Update Purchased Products
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try Self.checkVerified(result)

                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                #if DEBUG
                print("[StoreKit] Failed to verify transaction: \(error)")
                #endif
            }
        }

        purchasedProductIDs = purchased
    }

    // MARK: - Listen for Transactions
    private func listenForTransactions() -> Task<Void, Error> {
        Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try Self.checkVerified(result)
                    await updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    #if DEBUG
                    print("[StoreKit] Transaction verification failed: \(error)")
                    #endif
                }
            }
        }
    }

    // MARK: - Verify Transaction (pure function, no state access)
    nonisolated private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Errors
enum StoreKitError: LocalizedError, Sendable {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "トランザクションの検証に失敗しました"
        }
    }
}
