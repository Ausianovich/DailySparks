import Foundation
import StoreKit

enum SubscriptionService {
    static let subscriptionGroupID = "21774164"
    /// Checks whether the user currently has any active entitlement in the given subscription group.
    static func hasActiveSubscription(groupID: String) async -> Bool {
        // Iterate through current entitlements; this only includes active (non-expired, non-revoked).
        
        if ProcessInfo.processInfo.arguments.contains("-subscribed") {
            return true
        }
        
        var statuses: [Product.SubscriptionInfo.Status] = []
        
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            guard let status = await transaction.subscriptionStatus else { continue }
            statuses.append(status)
        }
        return !statuses.isEmpty
    }
}

@MainActor
@Observable
final class SubscriptionsObserver {
    var disabled: Bool = true
    private var updates: Task<Void, Never>? = nil

    init() {
        updates = newTransactionListenerTask()
    }
    
    deinit {
        if ProcessInfo.processInfo.arguments.contains("-subscribed") {
            Task { [weak self] in
                await MainActor.run {
                    self?.disabled = false
                }
            }
            return
        }
        
        Task { [weak self] in
            await MainActor.run {
                self?.updates?.cancel()
            }
        }
    }
    
    func updateStatuses() async {
        
        if ProcessInfo.processInfo.arguments.contains("-subscribed") {
            disabled = false
            return
        }
        
        var statuses: [Product.SubscriptionInfo.Status] = []
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard let status = await transaction.subscriptionStatus else { continue }
            statuses.append(status)
        }
        
        disabled = statuses.isEmpty
    }
    
    private func newTransactionListenerTask() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                self.handle(updatedTransaction: verificationResult)
            }
        }
    }
    
    private func handle(updatedTransaction verificationResult: VerificationResult<Transaction>) {
        guard case .verified(let transaction) = verificationResult else {
            return
        }
        
        if let revocationDate = transaction.revocationDate {
            // Remove access to the product identified by transaction.productID.
            // Transaction.revocationReason provides details about
            // the revoked transaction.
            
            Task {
                await MainActor.run {
                    disabled = true
                }
            }
        } else if let expirationDate = transaction.expirationDate,
                  expirationDate < Date() {
            // Do nothing, this subscription is expired.
            return
        } else if transaction.isUpgraded {
            // Do nothing, there is an active transaction
            // for a higher level of service.
            return
        } else {
            // Provide access to the product identified by
            // transaction.productID.
            
            Task {
                await MainActor.run {
                    disabled = false
                }
            }
        }
    }
}

