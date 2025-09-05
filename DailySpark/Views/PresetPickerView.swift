import SwiftUI

struct PresetPickerView: View {
    @Binding var selectedSituation: String
    @Binding var selectedAudience: String

    @State private var showAllSituations = false
    @State private var showAllAudiences = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PickerSection(
                    title: "Situations",
                    items: Presets.situations,
                    selected: selectedSituation,
                    isExpanded: $showAllSituations,
                    onSelect: { selectedSituation = $0 }
                )

                PickerSection(
                    title: "Audiences",
                    items: Presets.audiences,
                    selected: selectedAudience,
                    isExpanded: $showAllAudiences,
                    onSelect: { selectedAudience = $0 }
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tip: you can also type custom text on the previous screen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }
            .padding(16)
        }
        .navigationTitle("Choose Presets")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Use") { dismiss() }
                    .disabled(selectedSituation.isEmpty || selectedAudience.isEmpty)
            }
        }
    }
}

private struct PickerSection: View {
    let title: String
    let items: [String]
    let selected: String
    @Binding var isExpanded: Bool
    var onSelect: (String) -> Void

    private var orderedItems: [String] {
        if let idx = items.firstIndex(of: selected), !selected.isEmpty {
            var arr = items
            arr.remove(at: idx)
            return [selected] + arr
        }
        return items
    }

    private var displayItems: [String] {
        isExpanded ? orderedItems : Array(orderedItems.prefix(2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                if items.count > 2 {
                    Button(action: { withAnimation(.easeInOut) { isExpanded.toggle() } }) {
                        Label(isExpanded ? "Show less" : "Show more", systemImage: isExpanded ? "chevron.up" : "chevron.down")
                    }
                    .font(.footnote)
                    .buttonStyle(.plain)
                }
            }

            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(displayItems, id: \.self) { item in
                    PickerPresetCard(text: item, isSelected: item == selected) {
                        onSelect(item)
                        withAnimation(.easeInOut) { isExpanded = false }
                    }
                }
            }
        }
    }
}

private struct PickerPresetCard: View {
    let text: String
    var isSelected: Bool
    var action: () -> Void

    private var parts: (category: String?, label: String) {
        let comps = text.split(separator: "—", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        if comps.count == 2 { return (String(comps[0]), String(comps[1])) }
        return (nil, text)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let cat = parts.category, !cat.isEmpty {
                    ZStack {
                        Circle().fill((isSelected ? Color.accentColor : categoryColor(cat)).opacity(0.18))
                        Image(systemName: categoryIcon(cat))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.accentColor : categoryColor(cat))
                    }
                    .frame(width: 26, height: 26)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(parts.label)
                        .font(.subheadline)
                        .lineLimit(2)
                    if let cat = parts.category, !cat.isEmpty {
                        Text(cat)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor.opacity(0.8) : Color.clear, lineWidth: isSelected ? 1.5 : 0)
            )
        }
        .buttonStyle(.plain)
    }
}

private func categoryIcon(_ category: String) -> String {
    switch category.lowercased() {
    case "date": return "heart.fill"
    case "corporate", "work": return "briefcase.fill"
    case "friends": return "person.2.fill"
    case "family": return "house.fill"
    case "neighbors": return "building.2.fill"
    case "travel": return "airplane"
    case "events": return "ticket.fill"
    case "fitness": return "figure.walk"
    case "hobby": return "puzzlepiece.fill"
    case "culture": return "theatermasks.fill"
    default: return "sparkles"
    }
}

private func categoryColor(_ category: String) -> Color {
    switch category.lowercased() {
    case "date": return .pink
    case "corporate", "work": return .blue
    case "friends": return .purple
    case "family": return .orange
    case "neighbors": return .teal
    case "travel": return .mint
    case "events": return .indigo
    case "fitness": return .green
    case "hobby": return .brown
    case "culture": return .cyan
    default: return .gray
    }
}

