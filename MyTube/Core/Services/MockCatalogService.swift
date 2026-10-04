import Foundation

struct MockCatalogService: CatalogServicing {
    static let previewChannels: [Channel] = [
        Channel(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
            sourceID: "1",
            name: "Northern Lens",
            handle: "@northernlens",
            description: "Travel documentaries and city walks shot like premium TV intros.",
            avatarURL: nil,
            subscribersText: "1.2M subscribers",
            accentColorHex: "#F59E0B"
        ),
        Channel(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
            sourceID: "2",
            name: "Pixel Garage",
            handle: "@pixelgarage",
            description: "Tech builds, setup tours, and long-form engineering explainers.",
            avatarURL: nil,
            subscribersText: "845K subscribers",
            accentColorHex: "#3B82F6"
        ),
        Channel(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID(),
            sourceID: "3",
            name: "Open Air Live",
            handle: "@openairlive",
            description: "Concert sessions, intimate live sets, and behind-the-scenes edits.",
            avatarURL: nil,
            subscribersText: "402K subscribers",
            accentColorHex: "#EF4444"
        )
    ]

    static let previewVideos: [Video] = {
        let channels = previewChannels
        let sampleStreamURL = URL(string: "http://mytube.local:8000/videos/1/stream")!

        return [
            Video(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1") ?? UUID(), title: "Midnight Trains Through Tokyo", subtitle: "A silent 4K city ride", description: "Ride the Yamanote Line after midnight with cinematic street-level cutaways and station ambience.", thumbnailURL: URL(string: "https://i.ytimg.com/vi/V8P8ErpOT28/mqdefault.jpg"), durationSeconds: 2_814, streamURL: sampleStreamURL, channelID: channels[0].id, channelName: channels[0].name, publishedText: "2 days ago"),
            Video(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2") ?? UUID(), title: "How We Built a Living Room Studio", subtitle: "Lighting, sound, and mistakes", description: "A practical studio build for creator teams that need better production without a warehouse budget.", thumbnailURL: nil, durationSeconds: 1_032, streamURL: sampleStreamURL, channelID: channels[1].id, channelName: channels[1].name, publishedText: "1 week ago"),
            Video(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3") ?? UUID(), title: "Rooftop Session: Glass Harbor", subtitle: "Live performance", description: "A sunset performance recorded in one take with close-up crowd mics and skyline drones.", thumbnailURL: nil, durationSeconds: 487, streamURL: sampleStreamURL, channelID: channels[2].id, channelName: channels[2].name, publishedText: "5 days ago"),
            Video(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4") ?? UUID(), title: "Seoul Food Alleys at Dawn", subtitle: "Street food documentary", description: "An early-morning walk through hidden food corridors with minimal narration and dense local sound.", thumbnailURL: nil, durationSeconds: 1_566, streamURL: sampleStreamURL, channelID: channels[0].id, channelName: channels[0].name, publishedText: "3 weeks ago"),
            Video(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa5") ?? UUID(), title: "Cable Management for Real Homes", subtitle: "Desk setup overhaul", description: "A realistic teardown of a cluttered media desk with routing, power, and rack tips that actually scale.", thumbnailURL: nil, durationSeconds: 728, streamURL: sampleStreamURL, channelID: channels[1].id, channelName: channels[1].name, publishedText: "4 days ago"),
            Video(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa6") ?? UUID(), title: "Analog Dreams Live in Berlin", subtitle: "Synth performance", description: "A warm, analog-heavy set recorded in a former cinema with wide master shots and reactive lighting.", thumbnailURL: nil, durationSeconds: 3_245, streamURL: sampleStreamURL, channelID: channels[2].id, channelName: channels[2].name, publishedText: "6 days ago"),
            Video(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa7") ?? UUID(), title: "Canals of Amsterdam in Rain", subtitle: "Slow television", description: "A weather-heavy canal cruise designed as ambient background viewing for large-screen playback.", thumbnailURL: nil, durationSeconds: 4_812, streamURL: sampleStreamURL, channelID: channels[0].id, channelName: channels[0].name, publishedText: "1 month ago"),
            Video(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa8") ?? UUID(), title: "Inside a Dual-PC Streaming Rig", subtitle: "Performance breakdown", description: "When the capture workflow gets serious, this is the rig layout, network topology, and audio patching that matters.", thumbnailURL: nil, durationSeconds: 1_394, streamURL: sampleStreamURL, channelID: channels[1].id, channelName: channels[1].name, publishedText: "2 weeks ago"),
            Video(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa9") ?? UUID(), title: "Basement Jazz Broadcast", subtitle: "One-room concert film", description: "An intimate jazz recording staged for TV viewing with warm tungsten lighting and close camera choreography.", thumbnailURL: nil, durationSeconds: 2_108, streamURL: sampleStreamURL, channelID: channels[2].id, channelName: channels[2].name, publishedText: "8 days ago")
        ]
    }()

    static let previewPlaylists: [Playlist] = {
        let videos = previewVideos
        let channels = previewChannels

        return [
            Playlist(
                id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1") ?? UUID(),
                title: "Вечера на большом экране",
                summary: "Длинные кинематографичные видео для просмотра в гостиной.",
                artworkURL: nil,
                itemCount: 4,
                curator: "Редакция",
                videos: Array(videos.prefix(4))
            ),
            Playlist(
                id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2") ?? UUID(),
                title: "Школа авторов",
                summary: "Практические гайды по студии, рабочему месту и стримингу.",
                artworkURL: nil,
                itemCount: 3,
                curator: "Команда MyTube",
                videos: videos.filter { $0.channelID == channels[1].id }
            ),
            Playlist(
                id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb3") ?? UUID(),
                title: "Живые концерты",
                summary: "Концертные записи, смонтированные для просмотра на ТВ.",
                artworkURL: nil,
                itemCount: 3,
                curator: channels[2].name,
                videos: videos.filter { $0.channelID == channels[2].id }
            )
        ]
    }()

    static let previewStatisticsSummary = StatisticsSummary(
        totalVideos: 1_404,
        totalChannels: 24,
        totalVideoSizeGB: 646.6,
        totalDurationHours: 697.87,
        videosInProgress: 12
    )

    static let previewChannelStatistics: [ChannelStatistic] = {
        let channels = previewChannels

        return [
            ChannelStatistic(id: channels[0].id, sourceID: channels[0].sourceID, channelTitle: channels[0].name, videoCount: 312, totalSizeGB: 248.4),
            ChannelStatistic(id: channels[1].id, sourceID: channels[1].sourceID, channelTitle: channels[1].name, videoCount: 198, totalSizeGB: 173.9),
            ChannelStatistic(id: channels[2].id, sourceID: channels[2].sourceID, channelTitle: channels[2].name, videoCount: 140, totalSizeGB: 121.2),
            ChannelStatistic(id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-ccccccccccc4") ?? UUID(), sourceID: "4", channelTitle: "Studio Notes", videoCount: 64, totalSizeGB: 0.7),
            ChannelStatistic(id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-ccccccccccc5") ?? UUID(), sourceID: "5", channelTitle: "Quiet Channel", videoCount: 0, totalSizeGB: 0)
        ]
    }()

    static let previewDailyStatistics: [DailyStatistic] = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"

        let today = calendar.startOfDay(for: .now)
        let counts = [0, 0, 3, 5, 0, 2, 8, 4, 0, 0, 6, 1, 9, 3]

        return (0..<14).compactMap { offset -> DailyStatistic? in
            guard let day = calendar.date(byAdding: .day, value: offset - 13, to: today) else {
                return nil
            }

            let count = counts[offset]
            return DailyStatistic(
                id: formatter.string(from: day),
                date: day,
                videoCount: count,
                totalSizeGB: Double(count) * 0.9
            )
        }
    }()

    private let channels: [Channel]
    private let playlists: [Playlist]
    private let videosByChannel: [UUID: [Video]]
    private let failingStatistics: Bool

    init(
        channels: [Channel] = MockCatalogService.previewChannels,
        playlists: [Playlist] = MockCatalogService.previewPlaylists,
        videos: [Video] = MockCatalogService.previewVideos,
        failingStatistics: Bool = false
    ) {
        self.channels = channels
        self.playlists = playlists
        self.videosByChannel = Dictionary(grouping: videos, by: \.channelID)
        self.failingStatistics = failingStatistics
    }

    func fetchChannels(page: Int) async throws -> ChannelPage {
        try await Task.sleep(for: .milliseconds(80))

        let pageSize = 12
        let startIndex = max((page - 1) * pageSize, 0)
        let endIndex = min(startIndex + pageSize, channels.count)
        let slice = startIndex < channels.count ? Array(channels[startIndex..<endIndex]) : []

        return ChannelPage(
            channels: slice,
            currentPage: page,
            hasMorePages: endIndex < channels.count
        )
    }

    func fetchPlaylists() async throws -> [Playlist] {
        try await Task.sleep(for: .milliseconds(80))
        return playlists
    }

    func fetchVideos(page: Int) async throws -> VideoPage {
        try await Task.sleep(for: .milliseconds(60))

        let pageSize = 12
        let videos = MockCatalogService.previewVideos
        let startIndex = max((page - 1) * pageSize, 0)
        let endIndex = min(startIndex + pageSize, videos.count)
        let slice = startIndex < videos.count ? Array(videos[startIndex..<endIndex]) : []

        return VideoPage(
            videos: slice,
            currentPage: page,
            hasMorePages: endIndex < videos.count
        )
    }

    func fetchVideos(for channel: Channel, page: Int, sort: ChannelVideoSort) async throws -> VideoPage {
        try await Task.sleep(for: .milliseconds(60))

        let pageSize = 12
        let videos = sortedVideos(for: channel, sort: sort)
        let startIndex = max((page - 1) * pageSize, 0)
        let endIndex = min(startIndex + pageSize, videos.count)
        let slice = startIndex < videos.count ? Array(videos[startIndex..<endIndex]) : []

        return VideoPage(
            videos: slice,
            currentPage: page,
            hasMorePages: endIndex < videos.count
        )
    }

    func fetchStatisticsSummary() async throws -> StatisticsSummary {
        try await Task.sleep(for: .milliseconds(120))
        try throwIfFailingStatistics()
        return MockCatalogService.previewStatisticsSummary
    }

    func fetchChannelStatistics() async throws -> [ChannelStatistic] {
        try await Task.sleep(for: .milliseconds(120))
        try throwIfFailingStatistics()
        return MockCatalogService.previewChannelStatistics
    }

    func fetchDailyStatistics() async throws -> [DailyStatistic] {
        try await Task.sleep(for: .milliseconds(120))
        try throwIfFailingStatistics()
        return MockCatalogService.previewDailyStatistics
    }

    func fetchVideo(_ video: Video) async throws -> Video {
        video
    }

    func requestDownload(for video: Video) async throws -> Video {
        var queued = video
        queued.downloadState = .queued
        queued.isDownloadRequested = true
        return queued
    }

    func cancelDownload(for video: Video) async throws -> Video {
        var available = video
        available.downloadState = .available
        available.isDownloadRequested = false
        return available
    }

    private func throwIfFailingStatistics() throws {
        if failingStatistics {
            throw URLError(.timedOut)
        }
    }

    private func sortedVideos(for channel: Channel, sort: ChannelVideoSort) -> [Video] {
        let videos = videosByChannel[channel.id, default: []]

        switch sort {
        case .newest:
            return videos
        case .popular:
            return videos.enumerated()
                .sorted { lhs, rhs in
                    if lhs.element.durationSeconds != rhs.element.durationSeconds {
                        return (lhs.element.durationSeconds ?? 0) > (rhs.element.durationSeconds ?? 0)
                    }

                    return lhs.offset < rhs.offset
                }
                .map(\.element)
        }
    }
}
