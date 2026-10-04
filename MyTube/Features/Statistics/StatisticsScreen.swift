import SwiftUI

struct StatisticsScreen: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel = StatisticsViewModel()
    @State private var dailyMetric: DailyMetric = .count

    // Five fixed columns: the five summary tiles fill exactly one row on a 1920pt tvOS layout.
    private let summaryColumns = Array(
        repeating: GridItem(.flexible(), spacing: 24, alignment: .topLeading),
        count: 5
    )

    var body: some View {
        NavigationStack {
            ScreenBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        toolbar
                        summarySection
                        channelsSection
                        dailySection
                    }
                    .screenContentPadding()
                }
                .scrollIndicators(.hidden)
            }
            .navigationDestination(for: Channel.self) { channel in
                ChannelDetailScreen(channel: channel)
            }
            .navigationDestination(for: Video.self) { video in
                VideoDestinationView(video: video)
            }
        }
        .task {
            await viewModel.load(using: environment.catalogService)
        }
    }

    // MARK: - Toolbar

    // No screen title here: the tab bar already shows "Статистика".
    // Summary tiles are not focusable, so this button is the first focus target on the screen.
    private var toolbar: some View {
        HStack(spacing: 18) {
            Button {
                Task { await viewModel.refresh(using: environment.catalogService) }
            } label: {
                PillButtonLabel(
                    viewModel.isRefreshing ? "Обновление..." : "Обновить",
                    systemImage: "arrow.clockwise",
                    showsProgress: viewModel.isRefreshing
                )
            }
            .buttonStyle(.plain)
            .hoverEffectDisabled()

            Spacer(minLength: 0)
        }
        .focusSection()
    }

    // MARK: - Summary

    private var summarySection: some View {
        section(title: "Сводка") {
            switch viewModel.summary {
                case .loading:
                    loadingView
                case .failed:
                    failureView("Не удалось загрузить сводку.") {
                        await viewModel.retrySummary(using: environment.catalogService)
                    }
                case .loaded(let summary):
                    LazyVGrid(columns: summaryColumns, spacing: 24) {
                        ForEach(summaryTiles(for: summary)) { tile in
                            StatTileView(icon: tile.icon, value: tile.value, caption: tile.caption)
                        }
                    }
            }
        }
    }

    private struct SummaryTile: Identifiable {
        let icon: String
        let value: String
        let caption: String
        var id: String { caption }
    }

    private func summaryTiles(for summary: StatisticsSummary) -> [SummaryTile] {
        [
            SummaryTile(icon: "play.rectangle.fill", value: StatisticsFormatter.number(summary.totalVideos), caption: "Видео"),
            SummaryTile(icon: "dot.radiowaves.left.and.right", value: StatisticsFormatter.number(summary.totalChannels), caption: "Каналов"),
            SummaryTile(icon: "internaldrive.fill", value: StatisticsFormatter.size(gb: summary.totalVideoSizeGB), caption: "Объём"),
            SummaryTile(icon: "clock.fill", value: StatisticsFormatter.durationHours(summary.totalDurationHours), caption: "Длительность"),
            SummaryTile(icon: "arrow.down.circle.fill", value: StatisticsFormatter.number(summary.videosInProgress), caption: "Скачивается")
        ]
    }

    // MARK: - Channels

    private var channelsSection: some View {
        section(title: "По каналам") {
            switch viewModel.channels {
                case .loading:
                    loadingView
                case .failed:
                    failureView("Не удалось загрузить каналы.") {
                        await viewModel.retryChannels(using: environment.catalogService)
                    }
                case .loaded(let channels):
                    if channels.isEmpty {
                        ContentUnavailableView(
                            "Нет данных по каналам",
                            systemImage: "dot.radiowaves.left.and.right",
                            description: Text("Скачанных видео пока нет.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        LazyVStack(spacing: 18) {
                            ForEach(Array(channels.enumerated()), id: \.element.id) { item in
                                NavigationLink(value: item.element.makeChannel()) {
                                    ChannelStatRowView(rank: item.offset + 1, stat: item.element)
                                }
                                .hoverEffectDisabled()
                                .buttonStyle(.plain)
                            }
                        }
                        .focusSection()
                    }
            }
        }
    }

    // MARK: - Daily

    private var dailySection: some View {
        section(title: "По дням") {
            switch viewModel.daily {
                case .loading:
                    loadingView
                case .failed:
                    failureView("Не удалось загрузить статистику по дням.") {
                        await viewModel.retryDaily(using: environment.catalogService)
                    }
                case .loaded(let daily):
                    VStack(alignment: .leading, spacing: 24) {
                        metricToggle
                        // Focusable so the chart can be scrolled fully into view on tvOS.
                        DailyDownloadsChartView(data: daily, metric: dailyMetric)
                            .focusable()
                    }
                    .focusSection()
            }
        }
    }

    private var metricToggle: some View {
        HStack(spacing: 14) {
            ForEach(DailyMetric.allCases) { metric in
                Button {
                    dailyMetric = metric
                } label: {
                    PillButtonLabel(
                        metric.title,
                        isSelected: dailyMetric == metric,
                        minWidth: 220
                    )
                }
                .buttonStyle(.plain)
                .hoverEffectDisabled()
            }
        }
    }

    // MARK: - Shared building blocks

    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.title2.weight(.semibold))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var loadingView: some View {
        ProgressView("Загрузка...")
            .font(.title3)
            .frame(maxWidth: .infinity, minHeight: 160)
    }

    private func failureView(_ message: String, retry: @escaping () async -> Void) -> some View {
        VStack(spacing: 16) {
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.title3)
                .foregroundStyle(AppTheme.secondaryText)

            Button {
                Task { await retry() }
            } label: {
                PillButtonLabel("Повторить", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .hoverEffectDisabled()
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .padding(28)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }
}

#Preview("Loaded") {
    StatisticsScreen()
        .environment(AppEnvironment(catalogService: MockCatalogService()))
}

#Preview("Failed") {
    StatisticsScreen()
        .environment(AppEnvironment(catalogService: MockCatalogService(failingStatistics: true)))
}
