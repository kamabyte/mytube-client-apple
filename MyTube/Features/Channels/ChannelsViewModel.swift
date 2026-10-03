import Foundation

@MainActor
@Observable
final class ChannelsViewModel {
    private(set) var channels: [Channel] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var hasMoreChannels = true
    private(set) var errorMessage: String?
    private var currentPage = 0

    func load(using service: CatalogServicing) async {
        guard channels.isEmpty else { return }
        await refresh(using: service)
    }

    func refresh(using service: CatalogServicing) async {
        guard !isLoading else { return }

        isLoading = true
        isLoadingMore = false
        errorMessage = nil
        currentPage = 0
        hasMoreChannels = true

        do {
            let page = try await service.fetchChannels(page: 1)
            channels = page.channels
            currentPage = page.currentPage
            hasMoreChannels = page.hasMorePages
        } catch {
            errorMessage = "Не удалось загрузить каналы."
        }

        isLoading = false
    }

    func loadMoreIfNeeded(currentChannel channel: Channel, using service: CatalogServicing) async {
        guard hasMoreChannels, !isLoading, !isLoadingMore else { return }
        guard shouldLoadMore(after: channel) else { return }

        isLoadingMore = true

        do {
            let nextPage = currentPage + 1
            let page = try await service.fetchChannels(page: nextPage)
            channels.append(contentsOf: page.channels)
            currentPage = page.currentPage
            hasMoreChannels = page.hasMorePages
        } catch {
            errorMessage = "Не удалось загрузить ещё каналы."
        }

        isLoadingMore = false
    }

    private func shouldLoadMore(after channel: Channel) -> Bool {
        guard let index = channels.firstIndex(where: { $0.id == channel.id }) else {
            return false
        }

        let thresholdIndex = max(channels.count - 8, 0)
        return index >= thresholdIndex
    }
}
