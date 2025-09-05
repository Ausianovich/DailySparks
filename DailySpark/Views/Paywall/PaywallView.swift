import SwiftUI
import StoreKit

struct PaywallView: View {
    var onSuccess: (() -> Void)? = nil

    @State private var errorIsPresented = false
    @State private var error: Error? = nil

    private let promotions: [String] = [
        "Unlimited practice — any role, any scenario.",
        "Smart feedback — speak with confidence.",
        "More personas, more presets, more fun.",
        "Your data stays yours — full control.",
    ]

    var body: some View {
        SubscriptionStoreView(groupID: SubscriptionService.subscriptionGroupID, visibleRelationships: .upgrade) {
            VStack {
                ZStack {
                    VStack {
                        Image(.group)
                            .resizable()
                            .scaledToFill()
                    }
                    .containerRelativeFrame(.horizontal)
                    .clipped()
                    VStack {
                        Text("Ready for Any Conversation")
                            .font(.largeTitle)
                            .foregroundStyle(.bullets)
                            .multilineTextAlignment(.center)
                            .bold()
                    }
                    .padding()
                }
                VStack(alignment: .leading) {
                    ForEach(promotions, id: \.self) { text in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.bullets)
                            Text(text)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(Color.promoText)
                        }
                        .font(.title3)
                        .bold()
                    }
                }
                .padding(.horizontal, 12.0)
            }
        }
        .storeButton(.hidden, for: .cancellation)
        .storeButton(.visible, for: .restorePurchases)
        .subscriptionStorePolicyForegroundStyle(.white)
        .subscriptionStoreControlStyle(.buttons)
        .subscriptionStoreButtonLabel(.action)
        .background(LinearGradient(colors: [Color.accentColor, .white], startPoint: .top, endPoint: .bottom))
        .tint(Color.bullets)
        .onInAppPurchaseCompletion { _, result in
            switch result {
            case .success(.success):
                onSuccess?()
            case .failure(let error):
                self.error = error
                errorIsPresented = true
            default:
                break
            }
        }
        .alert(isPresented: $errorIsPresented, content: {
            Alert(
                title: Text("subscription_error"),
                message: Text(error?.localizedDescription ?? ""),
                dismissButton: .cancel(Text("ok"))
            )
        })
        .interactiveDismissDisabled(true)
    }
}

