import SwiftUI

struct ChannelCardView: View {
    @Environment(\.isFocused) private var isFocused

    let channel: Channel

    private let cornerRadius: CGFloat = 24
    private let thumbnailAspectRatio: CGFloat = 16 / 9

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            thumbnail

            Text(channel.name)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isFocused ? .white : Color.white.opacity(0.84))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
        }
        .zIndex(isFocused ? 1 : 0)
        .animation(.easeOut(duration: 0.18), value: isFocused)
        .focusEffectDisabled()
    }

    private var thumbnail: some View {
        ZStack(alignment: .bottomLeading) {
            thumbnailBackground

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.52)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .aspectRatio(thumbnailAspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(isFocused ? 0.96 : 0.08), lineWidth: 3)
        )
        .shadow(color: isFocused ? Color.black.opacity(0.4) : .clear, radius: 26, y: 16)
        .scaleEffect(isFocused ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.18), value: isFocused)
    }

    @ViewBuilder
    private var thumbnailBackground: some View {
        if let thumbnailURL = channel.avatarURL {
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
        } else {
            placeholderThumbnail
        }
    }

    private var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.17, blue: 0.24),
                        Color(red: 0.16, green: 0.24, blue: 0.34)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.68))
            }
    }
}

#Preview("Channel Card") {
    ScreenBackground {
        ChannelCardView(channel: MockCatalogService.previewChannels[0])
            .frame(width: 300)
            .padding(AppTheme.contentPadding)
    }
}
