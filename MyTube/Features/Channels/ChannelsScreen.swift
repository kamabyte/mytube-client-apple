import SwiftUI

struct ChannelsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel = ChannelsViewModel()

    private let columns = [
        GridItem(.adaptive(minimum: 260, maximum: 320), spacing: 20, alignment: .top)
    ]

    var body: some View {
        NavigationStack {
            ScreenBackground {
                Group {
                    if viewModel.channels.isEmpty && viewModel.isLoading {
                        ProgressView("Загрузка...")
                            .font(.title3)
                    } else if viewModel.channels.isEmpty {
                        ContentUnavailableView(
                            "Каналов не найдено",
                            systemImage: "dot.radiowaves.left.and.right",
                            description: Text(viewModel.errorMessage ?? "Подключите сервис каталога, чтобы загрузить каналы.")
                        )
                    } else {
                        ScrollView {
                            VStack(spacing: 24) {
                                LazyVGrid(columns: columns, spacing: 20) {
                                    ForEach(viewModel.channels) { channel in
                                        NavigationLink(value: channel) {
                                            ChannelCardView(channel: channel)
                                        }
                                        .hoverEffectDisabled()
                                        .buttonStyle(.plain)
                                        .task {
                                            await viewModel.loadMoreIfNeeded(
                                                currentChannel: channel,
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
                            .screenContentPadding()
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .navigationDestination(for: Channel.self) { channel in
                ChannelDetailScreen(channel: channel)
            }
            .navigationDestination(for: Video.self) { video in
                PlayerScreen(video: video)
            }
        }
        .task {
            await viewModel.load(using: environment.catalogService)
        }
    }
}

#Preview {
    ChannelsScreen()
        .environment(AppEnvironment.bootstrap())
}
