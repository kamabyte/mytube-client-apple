import SwiftUI

struct VideoCardView: View {
    @Environment(\.isFocused) private var isFocused

    let video: Video
    private let focusOverride: Bool?
    /// `nil` (the default) lets the card fill its grid cell — on tvOS the layout is always
    /// 1920x1080 points, so a hardcoded width quietly costs a whole column.
    private let cardWidth: CGFloat?

    init(video: Video, focusOverride: Bool? = nil, cardWidth: CGFloat? = nil) {
        self.video = video
        self.focusOverride = focusOverride
        self.cardWidth = cardWidth
    }

    private var showsFocusedState: Bool {
        focusOverride ?? isFocused
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            thumbnail
            VStack(alignment: .leading, spacing: 10) {
                Text(video.title)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(showsFocusedState ? .white : Color.white.opacity(0.74))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(video.channelName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(showsFocusedState ? Color.white.opacity(0.86) : Color.white.opacity(0.62))
                    .lineLimit(1)

                Text(video.publishedText)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(showsFocusedState ? Color.white.opacity(0.78) : Color.white.opacity(0.56))
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: cardWidth ?? .infinity, alignment: .topLeading)
        .zIndex(showsFocusedState ? 1 : 0)
        .focusEffectDisabled()
    }

    private var thumbnail: some View {
        ZStack {
            thumbnailBackground
            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.14),
                    Color.black.opacity(0.5)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .overlay(alignment: .bottomTrailing) {
            if let durationText {
                Text(durationText)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(showsFocusedState ? 0.84 : 0.74))
                    .clipShape(Capsule())
                    .padding(18)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(showsFocusedState ? 0.96 : 0.08), lineWidth: 3)
        )
        .shadow(color: showsFocusedState ? Color.black.opacity(0.4) : .clear, radius: 26, y: 16)
        .scaleEffect(showsFocusedState ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.18), value: showsFocusedState)
    }

    @ViewBuilder
    private var thumbnailBackground: some View {
        if let thumbnailURL = video.thumbnailURL {
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    placeholderThumbnail
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        } else {
            placeholderThumbnail
        }
    }

    private var placeholderThumbnail: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.24, green: 0.11, blue: 0.10),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .clipped()
    }

    private var durationText: String? {
        guard let durationSeconds = video.durationSeconds, durationSeconds > 0 else {
            return nil
        }

        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        let seconds = durationSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview("Focused") {
    VideoCardView(video: MockCatalogService.previewVideos[0], focusOverride: true)
        .padding(AppTheme.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
}

#Preview("Not Focused") {
    ScreenBackground {
        VideoCardView(video: MockCatalogService.previewVideos[0], focusOverride: false)
            .padding(AppTheme.contentPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .frame(width: 920, height: 620)
}
