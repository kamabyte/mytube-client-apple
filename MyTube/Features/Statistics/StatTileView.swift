import SwiftUI

/// Read-only summary tile: not focusable, so the remote skips straight to the
/// interactive parts of the screen.
struct StatTileView: View {
    let icon: String
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.82))

            Spacer(minLength: 0)

            Text(value)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(caption)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .padding(24)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
        )
    }
}

#Preview("Tiles") {
    ScreenBackground {
        HStack(spacing: 24) {
            StatTileView(icon: "play.rectangle.fill", value: "1 404", caption: "Видео")
            StatTileView(icon: "dot.radiowaves.left.and.right", value: "24", caption: "Каналов")
        }
        .screenContentPadding()
    }
}
