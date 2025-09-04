import SwiftUI
import StoreKit

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var page: Int = 0
    @State private var showPaywall: Bool = false
    @State var errorIsPresented: Bool = false
    @State private var error: Error? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    TabView(selection: $page) {
                        OBPage(
                            systemImage: "sparkles",
                            title: "Break the ice",
                            subtitle: "Generate light, safe conversation sparks for any situation."
                        ).tag(0)

                    OBPage(
                        systemImage: "bubble.left.and.text.bubble.right",
                        title: "Practice real chats",
                        subtitle: "Train with realistic personas and get gentle, actionable feedback."
                    ).tag(1)

                    OBPage(
                        systemImage: "book",
                        title: "Learn quick tips",
                        subtitle: "Short micro‑lessons to improve small talk fundamentals."
                    ).tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Bottom control for pages 0–2: wide Next / Let's start button
                    VStack(spacing: 12) {
                        Button(action: primaryAction) {
                            Text(page == 2 ? "Let's start" : "Next").bold()
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .transition(.opacity)
                }

                // Sheet for paywall is handled below via .sheet modifier
            }
            .navigationTitle(page < 3 ? "Welcome" : "Subscribe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showPaywall {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Skip") { presentPaywall() }
                    }
                }
            }
            .fullScreenCover(isPresented: $showPaywall, onDismiss: { finish() }) {
                NavigationStack {
                    SubscriptionStoreView(groupID: "E1B09FBE", visibleRelationships: .upgrade) {
                        VStack {
                            Spacer()
                            Text("unlock_potential_title")
                                .font(.title)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .bold()
                            Spacer()
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Generate dialogs")
                                    Text("Train your smalltalks skills")
                                }
                                .padding(.horizontal, 20.0)
                                Spacer()
                            }
                        }
                    }
                    .storeButton(.hidden, for: .cancellation)
                    .storeButton(.visible, for: .restorePurchases)
                    .subscriptionStorePolicyForegroundStyle(.white)
                    .subscriptionStoreControlStyle(.prominentPicker)
                    .subscriptionStoreControlIcon(icon: { subscription, info in
                        switch info.groupLevel {
                        case 1: Image(systemName: "pentagon.fill").foregroundStyle(Color.accentColor)
                        case 2: Image(systemName: "hexagon.fill").foregroundStyle(Color.accentColor)
                        default: EmptyView()
                        }
                    })
                    .onInAppPurchaseCompletion { product, result in
                        
                        switch result {
                        case .success(.success):
                            isPresented = false
                        case .failure(let error):
                            self.error = error
                            errorIsPresented = true
                        default:
                            break
                        }
                    }
                    .alert(isPresented: $errorIsPresented, content: {
                        Alert(title: Text("subscription_error"), message: Text(error?.localizedDescription ?? ""), dismissButton: .cancel(Text("ok"), action: {
                            errorIsPresented = false
                        }))
                    })
                }
                .interactiveDismissDisabled(true)
            }
        }
    }

    private func next() { withAnimation { page = min(page + 1, 2) } }
    private func primaryAction() {
        if page < 2 { next() } else { presentPaywall() }
    }
    private func presentPaywall() { showPaywall = true }
    private func completeOnboarding() { showPaywall = false }
    private func finish() { withAnimation { isPresented = false } }
}

private struct OBPage: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 24)
            Image(systemName: systemImage)
                .font(.system(size: 64))
                .foregroundStyle(.accent)
                .padding(.bottom, 8)
            Text(title)
                .font(.title2).bold()
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .padding(.horizontal)
    }
}
