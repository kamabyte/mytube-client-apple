import Foundation

@MainActor
@Observable
final class VideoDownloadViewModel {
    /// How often to re-check a queued or running download (an hour of video takes 3–4 minutes).
    private static let pollInterval: Duration = .seconds(5)

    private(set) var video: Video
    private(set) var isSending = false
    private(set) var errorMessage: String?

    init(video: Video) {
        self.video = video
    }

    var isWaiting: Bool {
        video.downloadState == .queued || video.downloadState == .downloading
    }

    /// Only someone's request can be cancelled; a video queued by its auto-download channel can't.
    var canCancel: Bool {
        video.downloadState == .queued && video.isDownloadRequested
    }

    func requestDownload(using service: CatalogServicing, tracker: DownloadTracker) async {
        await send(tracker: tracker) { try await service.requestDownload(for: $0) }
    }

    func cancelDownload(using service: CatalogServicing, tracker: DownloadTracker) async {
        await send(tracker: tracker) { try await service.cancelDownload(for: $0) }
    }

    /// Re-checks the server while the video is queued or downloading. Runs in the screen's
    /// `.task`, so it stops when the screen goes away.
    func pollWhileWaiting(using service: CatalogServicing, tracker: DownloadTracker) async {
        while isWaiting, !Task.isCancelled {
            try? await Task.sleep(for: Self.pollInterval)

            guard !Task.isCancelled else { return }

            if let fresh = try? await service.fetchVideo(video) {
                apply(fresh, tracker: tracker)
            }
        }
    }

    private func send(tracker: DownloadTracker, _ action: (Video) async throws -> Video) async {
        guard !isSending else { return }

        isSending = true
        errorMessage = nil

        do {
            apply(try await action(video), tracker: tracker)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Не удалось отправить запрос."
        }

        isSending = false
    }

    private func apply(_ fresh: Video, tracker: DownloadTracker) {
        video = fresh
        tracker.update(fresh)
    }
}
