import SwiftUI
import StoreKit
import UIKit

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var page: Int = 0
    @State private var showPaywall: Bool = false
    @State var errorIsPresented: Bool = false
    @State private var error: Error? = nil
    @State private var animateIcon: Bool = false
    @State private var pagerIsReady: Bool = false

    private let themes: [OBTheme] = [
        OBTheme(
            gradient: [Color.accentColor.opacity(0.35), Color.blue.opacity(0.15), Color.clear],
            tint: .accentColor
        ),
        OBTheme(
            gradient: [Color.purple.opacity(0.35), Color.blue.opacity(0.15), Color.clear],
            tint: .purple
        ),
        OBTheme(
            gradient: [Color.orange.opacity(0.35), Color.pink.opacity(0.15), Color.clear],
            tint: .orange
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic, subtle gradient background that shifts per page
                backgroundView
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    TabView(selection: $page) {
                        OBPage(
                            systemImage: "sparkles",
                            title: "Break the ice",
                            subtitle: "Generate light, safe conversation sparks for any situation.",
                            tint: themes[safe: 0]?.tint ?? .accentColor,
                            animate: animateIcon
                        )
                        .tag(0)

                    OBPage(
                        systemImage: "bubble.left.and.text.bubble.right",
                        title: "Practice real chats",
                        subtitle: "Train with realistic personas and get gentle, actionable feedback.",
                        tint: themes[safe: 1]?.tint ?? .accentColor,
                        animate: animateIcon
                    )
                    .tag(1)

                    OBPage(
                        systemImage: "book",
                        title: "Learn quick tips",
                        subtitle: "Short micro‑lessons to improve small talk fundamentals.",
                        tint: themes[safe: 2]?.tint ?? .accentColor,
                        animate: animateIcon
                    )
                    .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: page)

                    // Bottom control for pages 0–2: wide Next / Let's start button
                    VStack(spacing: 12) {
                        pageIndicator
                        Button(action: primaryAction) {
                            Text(page == 2 ? "Let's start" : "Next").bold()
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .sensoryFeedback(.impact(weight: .light), trigger: page)
                    }
                    .padding()
                    .transition(.opacity)
                }
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
                    SubscriptionStoreView(groupID: "21774164", visibleRelationships: .upgrade) {
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
                .interactiveDismissDisabled(true)
            }
        }
    }

    private func next() {
        page = min(page + 1, 2)
    }
    private func primaryAction() {
        if page < 2 {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            next()
        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            presentPaywall()
        }
    }
    private func presentPaywall() { showPaywall = true }
    private func completeOnboarding() { showPaywall = false }
    private func finish() { withAnimation { isPresented = false } }
}

let promotions: [String] = [
    "Unlimited practice — any role, any scenario.",
    "Smart feedback — speak with confidence.",
    "More personas, more presets, more fun.",
    "Your data stays yours — full control.",
]

private struct OBPage: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var tint: Color = .accentColor
    var animate: Bool = false

    @State private var float: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 24)

            ZStack {
                // Soft glow behind the icon
                Circle()
                    .fill(tint.opacity(0.25))
                    .frame(width: 140, height: 140)
                    .blur(radius: 24)
                    .scaleEffect(float ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: float)

                Image(systemName: systemImage)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 64, weight: .semibold, design: .rounded))
                    .foregroundStyle(tint)
                    .shadow(color: tint.opacity(0.35), radius: 12, x: 0, y: 6)
                    .scaleEffect(animate ? 1.06 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animate)
            }
            .padding(.bottom, 4)
            .onAppear { float = true }

            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(LinearGradient(colors: [tint, .primary], startPoint: .topLeading, endPoint: .bottomTrailing))

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

private struct OBTheme {
    let gradient: [Color]
    let tint: Color
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Background & Page Indicator
private extension OnboardingView {
    var backgroundView: some View {
        ZStack {
            let colors = themes[safe: page]?.gradient ?? [Color.accentColor.opacity(0.25), .clear]
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(0.9)

            // Decorative blobs with slow movement
            blob(color: .white.opacity(0.12), size: 220, x: 0.15, y: 0.2, spin: 24)
            blob(color: .white.opacity(0.10), size: 260, x: 0.85, y: 0.15, spin: -18)
            blob(color: .white.opacity(0.08), size: 300, x: 0.7, y: 0.8, spin: 14)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.6), value: page)
    }

    func blob(color: Color, size: CGFloat, x: CGFloat, y: CGFloat, spin: Double) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .blur(radius: 40)
                .position(x: w * x, y: h * y)
                .rotationEffect(.degrees(spin * Double(page)))
                .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: page)
        }
        .allowsHitTesting(false)
    }

    var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill((i == page ? (themes[safe: i]?.tint ?? .accentColor) : Color.secondary.opacity(0.25)))
                    .frame(width: i == page ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: page)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(page + 1) of 3")
    }
}

#Preview {
    OBPage(
        systemImage: "sparkles",
        title: "Break the ice",
        subtitle: "Generate light, safe conversation sparks for any situation."
    )
}
