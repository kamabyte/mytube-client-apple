import Foundation

@MainActor
@Observable
final class ChannelDetailViewModel {
    private(set) var videos: [Video] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var hasMoreVideos = true
    private(set) var errorMessage: String?
    private(set) var selectedSort: ChannelVideoSort = .newest
    private var currentPage = 0

    func load(channel: Channel, using service: CatalogServicing) async {
        guard videos.isEmpty else { return }
        await refresh(channel: channel, using: service)
    }

    func refresh(channel: Channel, using service: CatalogServicing) async {
        guard !isLoading else { return }

        isLoading = true
        isLoadingMore = false
        errorMessage = nil
        currentPage = 0
        hasMoreVideos = true

        do {
            let page = try await service.fetchVideos(for: channel, page: 1, sort: selectedSort)
            videos = page.videos
            currentPage = page.currentPage
            hasMoreVideos = page.hasMorePages
        } catch {
            errorMessage = "Не удалось загрузить видео."
        }

        isLoading = false
    }

    func loadMoreIfNeeded(currentVideo video: Video, channel: Channel, using service: CatalogServicing) async {
        guard hasMoreVideos, !isLoading, !isLoadingMore else { return }
        guard shouldLoadMore(after: video) else { return }

        isLoadingMore = true

        do {
            let nextPage = currentPage + 1
            let page = try await service.fetchVideos(for: channel, page: nextPage, sort: selectedSort)
            videos.append(contentsOf: page.videos)
            currentPage = page.currentPage
            hasMoreVideos = page.hasMorePages
        } catch {
            errorMessage = "Не удалось загрузить ещё видео."
        }

        isLoadingMore = false
    }

    private func shouldLoadMore(after video: Video) -> Bool {
        guard let index = videos.firstIndex(where: { $0.id == video.id }) else {
            return false
        }

        let thresholdIndex = max(videos.count - 6, 0)
        return index >= thresholdIndex
    }

    func updateSort(_ sort: ChannelVideoSort, channel: Channel, using service: CatalogServicing) async {
        guard selectedSort != sort else { return }

        selectedSort = sort
        await refresh(channel: channel, using: service)
    }

    func activateSort(_ sort: ChannelVideoSort, channel: Channel, using service: CatalogServicing) async {
        if selectedSort == sort {
            await refresh(channel: channel, using: service)
            return
        }

        await updateSort(sort, channel: channel, using: service)
    }
}
