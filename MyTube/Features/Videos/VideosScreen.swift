import SwiftUI

struct VideosScreen: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel = VideosViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 32),
        GridItem(.flexible(), spacing: 32),
        GridItem(.flexible(), spacing: 32)
    ]

    var body: some View {
        NavigationStack {
            ScreenBackground {
                ScrollView {
                    // No screen title: the tab bar already shows "Видео".
                    VStack(alignment: .leading, spacing: 28) {
                        if viewModel.videos.isEmpty && viewModel.isLoading {
                            ProgressView("Загрузка видео...")
                                .font(.title3)
                                .frame(maxWidth: .infinity)
                        } else if viewModel.videos.isEmpty {
                            ContentUnavailableView(
                                "Нет видео",
                                systemImage: "play.rectangle",
                                description: Text(viewModel.errorMessage ?? "Видео пока не появились.")
                            )
                            .frame(maxWidth: .infinity)
                        } else {
                            LazyVGrid(columns: columns, spacing: 36) {
                                ForEach(viewModel.videos) { video in
                                    NavigationLink(value: video) {
                                        VideoCardView(video: video)
                                    }
                                    .hoverEffectDisabled()
                                    .buttonStyle(.plain)
                                    .task {
                                        await viewModel.loadMoreIfNeeded(
                                            currentVideo: video,
                                            using: environment.catalogService
                                        )
                                    }
                                }
                            }

                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .padding(.bottom, 8)
                            }
                        }
                    }
                    .screenContentPadding()
                }
                .scrollIndicators(.hidden)
            }
            .navigationDestination(for: Video.self) { video in
                VideoDestinationView(video: video)
            }
        }
        .task {
            await viewModel.load(using: environment.catalogService)
        }
    }
}

#Preview {
    VideosScreen()
        .environment(AppEnvironment.bootstrap())
}
