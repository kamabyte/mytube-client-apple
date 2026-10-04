import Foundation

enum ChannelVideoSort: String, CaseIterable, Sendable {
    case newest
    case popular
}

protocol CatalogServicing {
    func fetchChannels(page: Int) async throws -> ChannelPage
    func fetchPlaylists() async throws -> [Playlist]
    func fetchVideos(for channel: Channel, page: Int, sort: ChannelVideoSort) async throws -> VideoPage
    func fetchVideos(page: Int) async throws -> VideoPage
    func fetchStatisticsSummary() async throws -> StatisticsSummary
    func fetchChannelStatistics() async throws -> [ChannelStatistic]
    func fetchDailyStatistics() async throws -> [DailyStatistic]

    /// Fresh copy of one video — polled while its download is queued or running.
    func fetchVideo(_ video: Video) async throws -> Video
    /// Asks the server to download a catalog video (same as "Скачать в медиатеку" on the web).
    func requestDownload(for video: Video) async throws -> Video
    func cancelDownload(for video: Video) async throws -> Video
}

struct ChannelPage {
    let channels: [Channel]
    let currentPage: Int
    let hasMorePages: Bool
}

struct VideoPage {
    let videos: [Video]
    let currentPage: Int
    let hasMorePages: Bool
}
