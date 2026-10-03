import SwiftUI

struct ChannelDetailScreen: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ChannelDetailViewModel()
    @FocusState private var focusedTab: ChannelVideoSort?

    let channel: Channel

    private let columns = [
        GridItem(.flexible(), spacing: 32),
        GridItem(.flexible(), spacing: 32),
        GridItem(.flexible(), spacing: 32)
    ]
    private let tabs: [ChannelVideoSort] = [.newest, .popular]

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    if viewModel.videos.isEmpty && viewModel.isLoading {
                        ProgressView("Загрузка видео...")
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                    } else if viewModel.videos.isEmpty {
                        ContentUnavailableView(
                            "Нет видео",
                            systemImage: "play.rectangle",
                            description: Text(viewModel.errorMessage ?? "На этом канале пока нет видео.")
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
                                        channel: channel,
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
        .task {
            await viewModel.load(channel: channel, using: environment.catalogService)
        }
        .onExitCommand {
            dismiss()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .center, spacing: 20) {
                AvatarView(url: channel.avatarURL, size: 84)

                VStack(alignment: .leading, spacing: 10) {
                    Text(channel.name)
                        .font(.system(size: 42, weight: .bold, design: .rounded))

                    // Channels opened from the Statistics tab carry no handle.
                    if !channel.handle.isEmpty {
                        Text(channel.handle)
                            .font(.headline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }

            tabBar
        }
    }

    private var tabBar: some View {
        HStack(spacing: 30) {
            ForEach(tabs, id: \.rawValue) { tab in
                ChannelSortTabButton(
                    title: title(for: tab),
                    isSelected: viewModel.selectedSort == tab
                ) {
                    await viewModel.activateSort(tab, channel: channel, using: environment.catalogService)
                }
                .focused($focusedTab, equals: tab)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
        .focusSection()
        .defaultFocus($focusedTab, .newest)
    }

    private func title(for sort: ChannelVideoSort) -> String {
        switch sort {
        case .newest:
            "Новые"
        case .popular:
            "Популярные"
        }
    }
}

private struct ChannelSortTabButton: View {
    let title: String
    let isSelected: Bool
    let onActivate: @Sendable () async -> Void

    var body: some View {
        Button {
            Task {
                await onActivate()
            }
        } label: {
            PillButtonLabel(title, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .hoverEffectDisabled()
    }
}

#Preview {
    NavigationStack {
        ChannelDetailScreen(channel: MockCatalogService.previewChannels[0])
            .environment(AppEnvironment.bootstrap())
    }
}
