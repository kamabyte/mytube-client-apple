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
