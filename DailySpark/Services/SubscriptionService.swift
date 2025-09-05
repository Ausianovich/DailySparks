import Foundation
import StoreKit

enum SubscriptionService {
    /// Checks whether the user currently has any active entitlement in the given subscription group.
    static func hasActiveSubscription(groupID: String) async -> Bool {
        // Iterate through current entitlements; this only includes active (non-expired, non-revoked).
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            if transaction.productType == .autoRenewable {
                if transaction.subscriptionGroupID == groupID { return true }
            }
        }
        return false
    }
}

