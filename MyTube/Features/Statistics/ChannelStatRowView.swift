import SwiftUI

struct ChannelStatRowView: View {
    @Environment(\.isFocused) private var isFocused

    let rank: Int
    let stat: ChannelStatistic

    var body: some View {
        HStack(spacing: 22) {
            Text("\(rank)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(isFocused ? .white : AppTheme.secondaryText)
                .frame(width: 54, alignment: .center)

            Text(stat.channelTitle)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(isFocused ? .white : Color.white.opacity(0.86))
                .lineLimit(1)

            Spacer(minLength: 16)

            metric(value: StatisticsFormatter.number(stat.videoCount), caption: "видео")
            metric(value: StatisticsFormatter.size(gb: stat.totalSizeGB), caption: "объём")

            Image(systemName: "chevron.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isFocused ? Color.white : Color.white.opacity(0.35))
                .frame(width: 30)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background(
            isFocused ? Color.white.opacity(0.18) : AppTheme.cardBackground,
            in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(Color.white.opacity(isFocused ? 0.96 : 0.14), lineWidth: isFocused ? 3 : 1)
        )
        .shadow(color: isFocused ? Color.black.opacity(0.4) : .clear, radius: 22, y: 12)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .zIndex(isFocused ? 1 : 0)
        .animation(.easeOut(duration: 0.18), value: isFocused)
        .focusEffectDisabled()
    }

    private func metric(value: String, caption: String) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(caption)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(minWidth: 140, alignment: .trailing)
    }
}

#Preview("Rows") {
    ScreenBackground {
        VStack(spacing: 18) {
            ChannelStatRowView(rank: 1, stat: MockCatalogService.previewChannelStatistics[0])
                .focusable()
            ChannelStatRowView(rank: 4, stat: MockCatalogService.previewChannelStatistics[3])
            ChannelStatRowView(rank: 5, stat: MockCatalogService.previewChannelStatistics[4])
        }
        .padding(AppTheme.contentPadding)
    }
}
