import SwiftUI

/// In place of the player for a video that isn't downloaded yet: its status and
/// "Скачать в медиатеку" — the same as the web client's download screen.
struct VideoDownloadScreen: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel: VideoDownloadViewModel

    private let onPlay: () -> Void

    init(video: Video, onPlay: @escaping () -> Void) {
        _viewModel = State(initialValue: VideoDownloadViewModel(video: video))
        self.onPlay = onPlay
    }

    private var video: Video {
        viewModel.video
    }

    var body: some View {
        ScreenBackground {
            HStack(alignment: .top, spacing: 56) {
                thumbnail

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(video.title)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .lineLimit(3)

                        Text([video.channelName, video.publishedText].filter { !$0.isEmpty }.joined(separator: " • "))
                            .font(.headline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    status
                    actions

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(Color(red: 1, green: 0.45, blue: 0.4))
                    }

                    if let description = video.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .screenContentPadding()
        }
        // Restarts when the state changes (queued → downloading), stops when it's done.
        .task(id: video.downloadState) {
            await viewModel.pollWhileWaiting(using: environment.catalogService, tracker: environment.downloads)
        }
    }

    private var thumbnail: some View {
        ZStack {
            Color.white.opacity(0.06)

            if let thumbnailURL = video.thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .opacity(video.isPlayable ? 1 : 0.7)
                    }
                }
            }
        }
        .frame(width: 900)
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.heroCornerRadius))
        .overlay(alignment: .topLeading) {
            if let badge = DownloadBadge(state: video.downloadState) {
                badge.padding(24)
            }
        }
    }

    private var status: some View {
        let copy = StatusCopy(video: video)

        return HStack(alignment: .top, spacing: 18) {
            Image(systemName: copy.systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(video.isPlayable ? Color.green : AppTheme.accent)
                .symbolEffect(.pulse, isActive: viewModel.isWaiting)

            VStack(alignment: .leading, spacing: 6) {
                Text(copy.title)
                    .font(.title3.bold())
                Text(copy.text)
                    .font(.callout)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        HStack(spacing: 24) {
            if video.isPlayable {
                Button(action: onPlay) {
                    PillButtonLabel("Смотреть", systemImage: "play.fill", isSelected: true)
                }
                .buttonStyle(.plain)
            }

            if video.downloadState == .available {
                Button {
                    Task {
                        await viewModel.requestDownload(using: environment.catalogService, tracker: environment.downloads)
                    }
                } label: {
                    PillButtonLabel("Скачать в медиатеку", systemImage: "icloud.and.arrow.down", showsProgress: viewModel.isSending)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSending)
            }

            if viewModel.canCancel {
                Button {
                    Task {
                        await viewModel.cancelDownload(using: environment.catalogService, tracker: environment.downloads)
                    }
                } label: {
                    PillButtonLabel("Отменить загрузку", systemImage: "xmark", showsProgress: viewModel.isSending)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSending)
            }
        }
        .focusSection()
    }
}

/// Status line texts — the same as on the web.
private struct StatusCopy {
    let systemImage: String
    let title: String
    let text: String

    init(video: Video) {
        switch video.downloadState {
        case .available:
            (systemImage, title, text) = (
                "icloud.and.arrow.down",
                "Видео ещё не скачано",
                "Час видео скачивается за 3–4 минуты. Когда файл будет готов, появится кнопка «Смотреть»."
            )
        case .queued where video.isDownloadRequested:
            (systemImage, title, text) = ("clock", "В очереди на загрузку", "Воркер возьмёт его, как только освободится. Экран обновится сам.")
        case .queued:
            (systemImage, title, text) = ("clock", "В очереди на загрузку", "Канал скачивается целиком — видео дождётся своей очереди.")
        case .downloading:
            (systemImage, title, text) = ("arrow.down.circle", "Скачивается…", "Обычно это пара минут.")
        case .downloaded:
            (systemImage, title, text) = ("checkmark.circle.fill", "Видео готово", "Можно смотреть.")
        case .unavailable:
            (systemImage, title, text) = ("nosign", "Видео недоступно", "YouTube его не отдаёт: удалено, закрыто или недоступно в регионе.")
        }
    }
}

#Preview {
    var video = MockCatalogService.previewVideos[0]
    video.downloadState = .available

    return NavigationStack {
        VideoDownloadScreen(video: video) {}
    }
    .environment(AppEnvironment(catalogService: MockCatalogService()))
}
