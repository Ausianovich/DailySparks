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

@Observable
final class SubscriptionsObserver {
    private(set) var disabled: Bool = true
    private var updates: Task<Void, Never>? = nil

    init() {
        observeTransactionUpdates()
    }
    
    deinit {
        if ProcessInfo.processInfo.arguments.contains("-subscribed") {
            disabled = false
            return
        }
        
        updates?.cancel()
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
 
    private func observeTransactionUpdates() {
        updates = Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                await self.handle(updatedTransaction: verificationResult)
            }
        }
    }
    
    private func handle(updatedTransaction verificationResult: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let transaction) = verificationResult else {
            return
        }
        
        if transaction.revocationDate != nil {
            disabled = true
            await transaction.finish()
        } else if let expirationDate = transaction.expirationDate,
                  expirationDate < .now {
            disabled = true
            await transaction.finish()
            return
        } else if transaction.isUpgraded {
            return
        } else {
            disabled = false
            await transaction.finish()
        }
    }
}

