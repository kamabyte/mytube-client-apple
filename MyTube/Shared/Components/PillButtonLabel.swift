import SwiftUI

/// Unified pill-shaped control label used across screens (refresh, sort tabs, chart metric switch).
/// Wrap it in a `Button` with `.buttonStyle(.plain)` — it draws its own focus and selection state.
struct PillButtonLabel: View {
    @Environment(\.isFocused) private var isFocused

    private let title: String
    private let systemImage: String?
    private let isSelected: Bool
    private let showsProgress: Bool
    private let minWidth: CGFloat?

    init(
        _ title: String,
        systemImage: String? = nil,
        isSelected: Bool = false,
        showsProgress: Bool = false,
        minWidth: CGFloat? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.showsProgress = showsProgress
        self.minWidth = minWidth
    }

    var body: some View {
        HStack(spacing: 12) {
            if showsProgress {
                ProgressView()
                    .controlSize(.small)
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
            }

            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(foreground)
        .frame(minWidth: minWidth)
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(Capsule().fill(background))
        .overlay(Capsule().strokeBorder(border, lineWidth: 1))
        .scaleEffect(isFocused ? 1.04 : 1.0)
        .animation(.easeOut(duration: 0.18), value: isFocused)
        .animation(.easeOut(duration: 0.18), value: isSelected)
        .focusEffectDisabled()
    }

    private var foreground: Color {
        if isFocused { return .black }
        return isSelected ? .white : Color.white.opacity(0.86)
    }

    private var background: Color {
        if isFocused { return Color.white.opacity(0.95) }
        return isSelected ? AppTheme.accent : Color.white.opacity(0.12)
    }

    private var border: Color {
        if isFocused || isSelected { return .clear }
        return Color.white.opacity(0.16)
    }
}

#Preview("Pills") {
    ScreenBackground {
        HStack(spacing: 18) {
            Button {} label: { PillButtonLabel("Обновить", systemImage: "arrow.clockwise") }
                .buttonStyle(.plain)
            Button {} label: { PillButtonLabel("Количество", isSelected: true, minWidth: 220) }
                .buttonStyle(.plain)
            Button {} label: { PillButtonLabel("Объём", minWidth: 220) }
                .buttonStyle(.plain)
            Button {} label: { PillButtonLabel("Обновление...", showsProgress: true) }
                .buttonStyle(.plain)
        }
        .screenContentPadding()
    }
}
