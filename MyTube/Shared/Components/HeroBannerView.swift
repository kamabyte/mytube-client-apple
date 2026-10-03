import SwiftUI

struct HeroBannerView: View {
    let video: Video

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppTheme.heroCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.86, green: 0.43, blue: 0.11),
                            Color(red: 0.48, green: 0.14, blue: 0.09),
                            Color(red: 0.10, green: 0.09, blue: 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.heroCornerRadius)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )

            HStack(alignment: .bottom, spacing: 24) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(video.channelName.uppercased())
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.72))

                    Text(video.title)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .lineLimit(2)

                    if let description = video.description, !description.isEmpty {
                        Text(description)
                            .font(.title3)
                            .foregroundStyle(Color.white.opacity(0.82))
                            .lineLimit(3)
                    }

                    Text(video.publishedText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.84))

                    NavigationLink(value: video) {
                        Label("Play Now", systemImage: "play.fill")
                            .font(.headline)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 14)
                            .background(Color.white, in: Capsule())
                            .foregroundStyle(Color.black)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(40)
        }
        .frame(height: 420)
    }
}
