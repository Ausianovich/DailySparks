import SwiftUI
import StoreKit
import UIKit

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var page: Int = 0
    @State private var showPaywall: Bool = false
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
        ),
        OBTheme(
            gradient: [Color.teal.opacity(0.35), Color.green.opacity(0.15), Color.clear],
            tint: .teal
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Return to dynamic gradient background (looked better)
                backgroundView
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    TabView(selection: $page) {
                        OBPage(
                            systemImage: "sparkles",
                            title: "Meet DailySpark",
                            subtitle: "Light, safe small‑talk help in seconds.",
                            tint: themes[safe: 0]?.tint ?? .accentColor,
                            animate: animateIcon,
                            bullets: [
                                "Get 3–5 tailored conversation sparks",
                                "Practice short, realistic chats with feedback",
                                "Keep favorites for later"
                            ]
                        )
                        .tag(0)

                        OBPage(
                            systemImage: "list.bullet",
                            title: "How it works",
                            subtitle: "Tell us the context — we’ll do the rest.",
                            tint: themes[safe: 1]?.tint ?? .accentColor,
                            animate: animateIcon,
                            bullets: [
                                "Pick situation and audience",
                                "Generate fresh questions and observations",
                                "Tap to Copy, Save, or Share",
                                "Train in 3–6 short turns"
                            ]
                        )
                        .tag(1)

                        OBPage(
                            systemImage: "lock.shield",
                            title: "Privacy & Safety",
                            subtitle: "You’re in control of what’s stored.",
                            tint: themes[safe: 2]?.tint ?? .accentColor,
                            animate: animateIcon,
                            bullets: [
                                "No transcripts saved by default",
                                "Opt in to store training history",
                                "Safety filters avoid sensitive topics"
                            ]
                        )
                        .tag(2)

                        // 4) Training preview: quick chat, up to 3 user turns
                        OBTrainingPreviewPage(
                            tint: themes[safe: 3]?.tint ?? .accentColor,
                            onFinish: { presentPaywall() }
                        )
                        .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: page)

                    // Bottom control: keep gradient CTA to match app buttons
                    VStack(spacing: 12) {
                        pageIndicator
                        if page < 3 {
                            Button(action: primaryAction) {
                                HStack(spacing: 10) {
                                    Image(systemName: page == 2 ? "checkmark.seal.fill" : "arrow.right.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    Text(page == 2 ? "Get Started" : "Next")
                                        .font(.headline.weight(.semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .clipShape(Capsule())
                                .shadow(color: .orange.opacity(0.25), radius: 10, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)
                            .sensoryFeedback(.impact(weight: .light), trigger: page)
                        }
                    }
                    .padding()
                    .transition(.opacity)
                }
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showPaywall {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Skip") { presentPaywall() }
                    }
                }
            }
            .fullScreenCover(isPresented: $showPaywall, onDismiss: { finish() }) {
                PaywallView {
                    // purchase success
                    showPaywall = false
                }
            }
        }
    }

    private func next() {
        page = min(page + 1, 3)
    }
    private func primaryAction() {
        if page < 3 {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            next()
        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            presentPaywall()
        }
    }
    private func presentPaywall() {
        // Check subscription first; only show paywall if needed
        Task { await presentPaywallChecked() }
    }
    @MainActor
    private func presentPaywallChecked() async {
        let hasSub = await SubscriptionService.hasActiveSubscription(groupID: SubscriptionService.subscriptionGroupID)
        if hasSub {
            finish()
        } else {
            showPaywall = true
        }
    }
    private func completeOnboarding() { showPaywall = false }
    private func finish() { withAnimation { isPresented = false } }
}

// promotions moved into PaywallView

private struct OBPage: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var tint: Color = .accentColor
    var animate: Bool = false
    var bullets: [String] = []

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

            if !bullets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(bullets.indices, id: \.self) { i in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(tint)
                                .font(.subheadline)
                                .accessibilityHidden(true)
                            Text(bullets[i])
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }

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
            ForEach(0..<4) { i in
                Capsule()
                    .fill((i == page ? (themes[safe: i]?.tint ?? .accentColor) : Color.secondary.opacity(0.25)))
                    .frame(width: i == page ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: page)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(page + 1) of 4")
    }
}

// MARK: - Training Preview Page
private struct OBTrainingPreviewPage: View {
    var tint: Color = .accentColor
    var onFinish: () -> Void

    struct Msg: Identifiable { let id = UUID(); let isUser: Bool; var text: String }

    @State private var messages: [Msg] = [
        .init(isUser: false, text: "Hi! I’m Alex. Want to try a super short practice chat?")
    ]
    @State private var input: String = ""
    @State private var thinking: Bool = false
    @State private var isStreaming: Bool = false
    @State private var streamTask: Task<Void, Never>? = nil
    @FocusState private var focused: Bool

    private var userTurnsCount: Int { messages.filter { $0.isUser }.count }
    private var limitReached: Bool { userTurnsCount >= 3 }

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 8)
            // Header
            Text("Try a quick chat")
                .font(.title3.bold())
                .foregroundStyle(LinearGradient(colors: [tint, .primary], startPoint: .topLeading, endPoint: .bottomTrailing))
            Text("Say up to three lines to get a feel.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            // Chat area
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { m in
                        HStack(alignment: .bottom) {
                            if m.isUser { Spacer(minLength: 40) }
                            OBPreviewMessageRow(isUser: m.isUser, text: m.text, tint: tint)
                                .frame(maxWidth: .infinity, alignment: m.isUser ? .trailing : .leading)
                            if !m.isUser { Spacer(minLength: 40) }
                        }
                    }
                    if thinking {
                        HStack {
                            ProgressView().scaleEffect(0.8)
                            Text("Typing…").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.leading, 8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            if limitReached {
                Button(action: { cancelStream(); onFinish() }) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 16, weight: .bold))
                        Text("Finish and get started")
                            .font(.headline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .orange.opacity(0.25), radius: 10, x: 0, y: 6)
                }
                .padding(.horizontal)
            } else {
                HStack(spacing: 8) {
                    TextField("Type a short line…", text: $input, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
                        .lineLimit(2)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 18).fill(Color(UIColor.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18).stroke(Color(UIColor.separator).opacity(0.25))
                        )
                        .focused($focused)
                        .submitLabel(.send)
                        .onSubmit { send() }

                    Button(action: send) {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 16, weight: .bold))
                            .padding(8)
                            .background(Circle().fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    }
                    .disabled(isStreaming || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
        .onChange(of: userTurnsCount) { _, new in
            if new >= 3 { focused = false }
        }
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !limitReached, !isStreaming else { return }
        messages.append(.init(isUser: true, text: text))
        input = ""
        startStreamingReply()
    }

    private func startStreamingReply() {
        // Cancel previous stream if any
        streamTask?.cancel()
        isStreaming = true
        thinking = true
        // Snapshot transcript before adding placeholder
        let transcriptTurns: [DialogueTurn] = messages.map { m in
            DialogueTurn(role: m.isUser ? .user : .ai, text: m.text)
        }
        // Add placeholder AI message
        messages.append(.init(isUser: false, text: ""))
        let aiIndex = messages.count - 1
        let persona = "Friendly, curious conversation partner; keeps things light, warm, and safe."
        let context = "Casual small talk (onboarding preview)"
        let assistantName = "Alex"
        streamTask = Task {
            do {
                let stream = await AIClient.shared.streamTrainingReply(
                    persona: persona,
                    context: context,
                    assistantName: assistantName,
                    transcript: transcriptTurns,
                    locale: "en",
                    model: "gpt-4o-mini"
                )
                for try await delta in stream {
                    await MainActor.run {
                        if aiIndex < messages.count {
                            messages[aiIndex].text.append(contentsOf: delta)
                            thinking = false
                        }
                    }
                }
            } catch {
                // Graceful fallback to a simple canned reply if API is unavailable
                let fallback = "Got it! What do you like most about it?"
                await MainActor.run {
                    if aiIndex < messages.count { messages[aiIndex].text = fallback }
                }
            }
            await MainActor.run {
                isStreaming = false
                thinking = false
            }
        }
    }

    private func cancelStream() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
        thinking = false
    }
}

// Simple message bubble for the onboarding training preview
private struct OBPreviewMessageRow: View {
    let isUser: Bool
    let text: String
    var tint: Color = .accentColor

    var body: some View {
        Group {
            if isUser {
                Text(text)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
            } else {
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(UIColor.separator).opacity(0.2))
                    )
            }
        }
    }
}

#Preview {
    OBPage(
        systemImage: "sparkles",
        title: "Meet DailySpark",
        subtitle: "Light, safe small‑talk help in seconds.",
        bullets: [
            "Get 3–5 tailored conversation sparks",
            "Practice short, realistic chats with feedback",
            "Keep favorites for later"
        ]
    )
}
