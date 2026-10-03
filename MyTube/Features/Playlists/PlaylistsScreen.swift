import SwiftUI

struct PlaylistsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel = PlaylistsViewModel()

    private let columns = [
        GridItem(.flexible(minimum: 480), spacing: 28),
        GridItem(.flexible(minimum: 480), spacing: 28)
    ]

    var body: some View {
        NavigationStack {
            ScreenBackground {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 28) {
                        ForEach(viewModel.playlists) { playlist in
                            NavigationLink(value: playlist) {
                                playlistCard(playlist)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .screenContentPadding()
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Плейлисты")
            .navigationDestination(for: Playlist.self) { playlist in
                playlistDetail(playlist)
            }
            .navigationDestination(for: Video.self) { video in
                PlayerScreen(video: video)
            }
        }
        .task {
            await viewModel.load(using: environment.catalogService)
        }
    }

    private func playlistCard(_ playlist: Playlist) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.41, blue: 0.34),
                            Color(red: 0.08, green: 0.17, blue: 0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)
                .overlay(alignment: .bottomLeading) {
                    Text("\(playlist.itemCount) видео")
                        .font(.headline)
                        .padding(18)
                }

            Text(playlist.title)
                .font(.title3.weight(.semibold))

            Text(playlist.summary)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)
        }
        .padding(22)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    private func playlistDetail(_ playlist: Playlist) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(playlist.title)
                    .font(.system(size: 44, weight: .bold, design: .rounded))

                Text("\(playlist.curator) • \(playlist.itemCount) видео")
                    .font(.headline)
                    .foregroundStyle(AppTheme.secondaryText)

                ForEach(playlist.videos) { video in
                    NavigationLink {
                        PlayerScreen(video: video, queue: playlist.videos)
                    } label: {
                        HStack(spacing: 18) {
                            VideoCardView(video: video)
                                .frame(width: 420)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(video.title)
                                    .font(.title3.weight(.semibold))

                                if let description = video.description, !description.isEmpty {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.secondaryText)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .screenContentPadding()
        }
        .background(AppTheme.pageGradient.ignoresSafeArea())
    }
}
