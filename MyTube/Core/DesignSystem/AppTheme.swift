import SwiftUI

enum AppTheme {
    static let pageGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.08, blue: 0.12),
            Color(red: 0.09, green: 0.12, blue: 0.18),
            Color(red: 0.15, green: 0.14, blue: 0.20)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = Color(red: 0.35, green: 0.55, blue: 1.0)
    static let cardBackground = Color.white.opacity(0.08)
    static let cardBorder = Color.white.opacity(0.14)
    static let secondaryText = Color.white.opacity(0.72)

    static let heroCornerRadius: CGFloat = 32
    static let cardCornerRadius: CGFloat = 22
    static let shelfSpacing: CGFloat = 28
    static let contentPadding: CGFloat = 10

    // Page margins: tvOS needs room for overscan and for the focus scale of edge cards.
    static let contentHorizontalPadding: CGFloat = 44
    static let contentVerticalPadding: CGFloat = 28
}

extension View {
    /// Standard page margins for a screen's scrollable content.
    func screenContentPadding() -> some View {
        padding(.horizontal, AppTheme.contentHorizontalPadding)
            .padding(.vertical, AppTheme.contentVerticalPadding)
    }
}
