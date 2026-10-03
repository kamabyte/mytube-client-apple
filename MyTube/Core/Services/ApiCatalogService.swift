import Foundation

struct ApiCatalogService: CatalogServicing
{
    /// Server address from Info.plist (`MyTubeAPIBaseURL` ← `MYTUBE_API_BASE_URL` in Config/*.xcconfig).
    static var configuredBaseURL: URL {
        if let value = Bundle.main.object(forInfoDictionaryKey: "MyTubeAPIBaseURL") as? String,
           let url = URL(string: value), url.host != nil {
            return url
        }
        return URL(string: "http://mytube.local:8000")!
    }

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let fallbackService: CatalogServicing?

    init(
        baseURL: URL = ApiCatalogService.configuredBaseURL,
        session: URLSession = .shared,
        fallbackService: CatalogServicing? = MockCatalogService()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.fallbackService = fallbackService

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func fetchChannels(page: Int) async throws -> ChannelPage {
        do {
            let response = try await request(
                PaginatedResponse<ChannelResponse>.self,
                endpoint: .channels(page: page)
            )

            return ChannelPage(
                channels: response.data.map { $0.toDomain(baseURL: baseURL) },
                currentPage: response.meta?.currentPage ?? page,
                hasMorePages: response.hasMorePages(fallbackCurrentPage: page)
            )
        } catch {
            if let fallbackService {
                return try await fallbackService.fetchChannels(page: page)
            }

            throw error
        }
    }

    func fetchPlaylists() async throws -> [Playlist] {
        if let fallbackService {
            return try await fallbackService.fetchPlaylists()
        }

        return []
    }

    func fetchVideos(for channel: Channel, page: Int, sort: ChannelVideoSort) async throws -> VideoPage {
        do {
            let response = try await request(
                PaginatedResponse<VideoResponse>.self,
                endpoint: .videos(channelSourceID: channel.sourceID, page: page, sort: sort)
            )

            return VideoPage(
                videos: response.data.map {
                    $0.toDomain(baseURL: baseURL, channelID: channel.id, channelName: channel.name)
                },
                currentPage: response.meta?.currentPage ?? page,
                hasMorePages: response.hasMorePages(fallbackCurrentPage: page)
            )
        } catch {
            if let fallbackService {
                return try await fallbackService.fetchVideos(for: channel, page: page, sort: sort)
            }

            throw error
        }
    }
    
    func fetchVideos(page: Int) async throws -> VideoPage {
        do {
            let response = try await request(
                PaginatedResponse<VideoResponse>.self,
                endpoint: .videos(page: page, sort: .newest)
            )

            return VideoPage(
                videos: response.data.map { $0.toDomain(baseURL: baseURL) },
                currentPage: response.meta?.currentPage ?? page,
                hasMorePages: response.hasMorePages(fallbackCurrentPage: page)
            )
        } catch {
            if let fallbackService {
                return try await fallbackService.fetchVideos(page: page)
            }

            throw error
        }
    }

    // Statistics endpoints intentionally do NOT fall back to `fallbackService`:
    // the Statistics screen surfaces loading/error per section, so errors must propagate.
    func fetchStatisticsSummary() async throws -> StatisticsSummary {
        let response = try await request(StatisticsSummaryResponse.self, endpoint: .statistics)
        return response.toDomain()
    }

    func fetchChannelStatistics() async throws -> [ChannelStatistic] {
        let response = try await request([ChannelStatisticResponse].self, endpoint: .statisticsChannels)
        return response.map { $0.toDomain() }
    }

    func fetchDailyStatistics() async throws -> [DailyStatistic] {
        let response = try await request([DailyStatisticResponse].self, endpoint: .statisticsDaily)
        return response.compactMap { $0.toDomain() }
    }
}

private extension ApiCatalogService {
    func request<Response: Decodable>(_ responseType: Response.Type, endpoint: Endpoint) async throws -> Response {
        let request = try makeRequest(for: endpoint)
        let (data, urlResponse) = try await session.data(for: request)

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed(statusCode: httpResponse.statusCode, payload: data)
        }

        do {
            return try decoder.decode(responseType, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    func makeRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appending(path: endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL(endpoint.path)
        }

        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL(endpoint.path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = endpoint.body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return request
    }

}

private extension ApiCatalogService {
    struct PaginatedResponse<Resource: Decodable>: Decodable {
        let data: [Resource]
        let meta: PaginationMeta?
        let links: PaginationLinks?

        func hasMorePages(fallbackCurrentPage: Int) -> Bool {
            if links?.next != nil {
                return true
            }

            if let meta {
                return meta.currentPage < meta.lastPage
            }

            return !data.isEmpty && fallbackCurrentPage == 1
        }
    }

    struct PaginationMeta: Decodable {
        let currentPage: Int
        let lastPage: Int

        enum CodingKeys: String, CodingKey {
            case currentPage = "current_page"
            case lastPage = "last_page"
        }
    }

    struct PaginationLinks: Decodable {
        let next: String?
    }

    struct ChannelResponse: Decodable {
        let id: APIIdentifier
        let name: String
        let thumbnail: String?
        let videosCount: Int?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case thumbnail
            case videosCount = "videos_count"
        }

        func toDomain(baseURL: URL) -> Channel {
            Channel(
                id: id.stableUUID(namespace: "channel"),
                sourceID: id.rawValue,
                name: name,
                handle: "@\(slug(from: name))",
                description: "Channel imported from API.",
                avatarURL: resolvedURL(from: thumbnail, baseURL: baseURL),
                subscribersText: subscriberCountText(videosCount),
                accentColorHex: accentColor(for: id.stableUUID(namespace: "channel"))
            )
        }
    }

    struct StatisticsSummaryResponse: Decodable {
        let totalVideos: Int
        let totalChannels: Int
        let totalVideoSizeGB: Double
        let totalDurationHours: Double
        let videosInProgress: Int

        // `total_video_size` / `total_duration_seconds` are deliberately not decoded:
        // on a 32-bit server they arrive as strings. We only consume the always-numeric
        // `*_gb` / `*_hours` fields plus the integer counts.
        enum CodingKeys: String, CodingKey {
            case totalVideos = "total_videos"
            case totalChannels = "total_channels"
            case totalVideoSizeGB = "total_video_size_gb"
            case totalDurationHours = "total_duration_hours"
            case videosInProgress = "videos_in_progress"
        }

        func toDomain() -> StatisticsSummary {
            StatisticsSummary(
                totalVideos: totalVideos,
                totalChannels: totalChannels,
                totalVideoSizeGB: totalVideoSizeGB,
                totalDurationHours: totalDurationHours,
                videosInProgress: videosInProgress
            )
        }
    }

    struct ChannelStatisticResponse: Decodable {
        let channelID: APIIdentifier
        let channelTitle: String
        let videoCount: Int
        let totalSizeGB: Double

        // `total_size_bytes` is deliberately not decoded (string on 32-bit servers).
        enum CodingKeys: String, CodingKey {
            case channelID = "channel_id"
            case channelTitle = "channel_title"
            case videoCount = "video_count"
            case totalSizeGB = "total_size_gb"
        }

        func toDomain() -> ChannelStatistic {
            ChannelStatistic(
                id: channelID.stableUUID(namespace: "channel"),
                sourceID: channelID.rawValue,
                channelTitle: channelTitle,
                videoCount: videoCount,
                totalSizeGB: totalSizeGB
            )
        }
    }

    struct DailyStatisticResponse: Decodable {
        let date: String
        let videoCount: Int
        let totalSizeGB: Double

        enum CodingKeys: String, CodingKey {
            case date
            case videoCount = "video_count"
            case totalSizeGB = "total_size_gb"
        }

        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()

        func toDomain() -> DailyStatistic? {
            guard let parsedDate = Self.dateFormatter.date(from: date) else {
                return nil
            }

            return DailyStatistic(
                id: date,
                date: parsedDate,
                videoCount: videoCount,
                totalSizeGB: totalSizeGB
            )
        }
    }

    struct VideoResponse: Decodable {
        let id: APIIdentifier
        let channelID: APIIdentifier
        let name: String
        let description: String?
        let thumbnail: URL?
        let durationSeconds: Int?
        let videoURL: String?
        let publishedAt: Date?
        let channel: ChannelResponse?

        enum CodingKeys: String, CodingKey {
            case id
            case channelID = "channel_id"
            case name
            case description
            case thumbnail
            case durationSeconds = "duration_seconds"
            case videoURL = "video_url"
            case publishedAt = "published_at"
            case channel
        }

        func toDomain(baseURL: URL, channelID: UUID, channelName: String) -> Video {
            let resolvedStreamURL = resolvedURL(from: videoURL, baseURL: baseURL)
                ?? baseURL.appending(path: "videos/\(id.rawValue)/stream")

            return Video(
                id: id.stableUUID(namespace: "video"),
                title: name,
                subtitle: channelName,
                description: description,
                thumbnailURL: thumbnail,
                durationSeconds: durationSeconds,
                streamURL: resolvedStreamURL,
                channelID: channelID,
                channelName: channelName,
                publishedText: publishedText(publishedAt)
            )
        }

        func toDomain(baseURL: URL) -> Video {
            let resolvedChannelID = channel?.id.stableUUID(namespace: "channel")
                ?? self.channelID.stableUUID(namespace: "channel")
            let resolvedChannelName = channel?.name ?? ""

            return toDomain(
                baseURL: baseURL,
                channelID: resolvedChannelID,
                channelName: resolvedChannelName
            )
        }
    }

    struct APIIdentifier: Decodable {
        let rawValue: String

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let stringValue = try? container.decode(String.self) {
                rawValue = stringValue
                return
            }

            if let intValue = try? container.decode(Int.self) {
                rawValue = String(intValue)
                return
            }

            throw DecodingError.typeMismatch(
                String.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected string or integer API identifier."
                )
            )
        }

        func stableUUID(namespace: String) -> UUID {
            let bytes = Array("\(namespace):\(rawValue)".utf8)
            var output = Array(repeating: UInt8(0), count: 16)

            for (index, byte) in bytes.enumerated() {
                output[index % 16] = output[index % 16] &+ byte &+ UInt8(index)
            }

            output[6] = (output[6] & 0x0F) | 0x40
            output[8] = (output[8] & 0x3F) | 0x80

            return UUID(uuid: (
                output[0], output[1], output[2], output[3],
                output[4], output[5], output[6], output[7],
                output[8], output[9], output[10], output[11],
                output[12], output[13], output[14], output[15]
            ))
        }
    }

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }

    struct Endpoint {
        let method: HTTPMethod
        let path: String
        let queryItems: [URLQueryItem]
        let body: [String: Any]?

        static func channels(page: Int, pageSize: Int = 20) -> Endpoint {
            Endpoint(
                method: .get,
                path: "channels",
                queryItems: [
                    URLQueryItem(name: "sort", value: "name"),
                    URLQueryItem(name: "fields", value: "id,name,thumbnail"),
                    URLQueryItem(name: "page[number]", value: String(page)),
                    URLQueryItem(name: "page[size]", value: String(pageSize))
                ],
                body: nil
            )
        }

        static func videos(channelSourceID: String? = nil, page: Int, pageSize: Int = 20, sort: ChannelVideoSort) -> Endpoint {
            let sortValue = switch sort {
            case .newest:
                "-published_at"
            case .popular:
                "-view_count"
            }
            
            var queryItems = [
                URLQueryItem(name: "include", value: "channel"),
                URLQueryItem(name: "page[number]", value: String(page)),
                URLQueryItem(name: "page[size]", value: String(pageSize)),
                URLQueryItem(name: "sort", value: sortValue)
            ]
            
            if channelSourceID != nil {
                queryItems.append(URLQueryItem(name: "filter[channel_id]", value: channelSourceID))
            }

            return Endpoint(
                method: .get,
                path: "videos",
                queryItems: queryItems,
                body: nil
            )
        }

        static let statistics = Endpoint(
            method: .get,
            path: "statistics",
            queryItems: [],
            body: nil
        )

        static let statisticsChannels = Endpoint(
            method: .get,
            path: "statistics/channels",
            queryItems: [],
            body: nil
        )

        static let statisticsDaily = Endpoint(
            method: .get,
            path: "statistics/daily",
            queryItems: [],
            body: nil
        )
    }

    enum APIError: LocalizedError {
        case invalidURL(String)
        case invalidResponse
        case requestFailed(statusCode: Int, payload: Data)
        case decodingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL(let path):
                return "Invalid API URL for path \(path)."
            case .invalidResponse:
                return "The server response was not an HTTP response."
            case .requestFailed(let statusCode, let payload):
                let message = String(data: payload, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let suffix = message.flatMap { $0.isEmpty ? nil : $0 } ?? "No response body."
                return "API request failed with status \(statusCode): \(suffix)"
            case .decodingFailed(let error):
                return "Failed to decode API response: \(error.localizedDescription)"
            }
        }
    }
}

private extension ApiCatalogService.ChannelResponse {
    func subscriberCountText(_ videosCount: Int?) -> String {
        guard let videosCount else {
            return "Subscribers unavailable"
        }

        return "\(videosCount) videos"
    }

    func accentColor(for id: UUID) -> String {
        let palette = ["#F59E0B", "#3B82F6", "#EF4444", "#10B981", "#8B5CF6", "#EC4899"]
        let checksum = id.uuidString.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + Int(scalar.value)
        }
        let index = checksum % palette.count
        return palette[index]
    }

    func slug(from value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "")
    }

    func resolvedURL(from path: String?, baseURL: URL) -> URL? {
        guard let path, !path.isEmpty else {
            return nil
        }

        if let absoluteURL = URL(string: path), absoluteURL.scheme != nil {
            return absoluteURL
        }

        return URL(string: path, relativeTo: baseURL)?.absoluteURL
    }
}

private extension ApiCatalogService.VideoResponse {
    func resolvedURL(from path: String?, baseURL: URL) -> URL? {
        guard let path, !path.isEmpty else {
            return nil
        }

        if let absoluteURL = URL(string: path), absoluteURL.scheme != nil {
            return absoluteURL
        }

        return URL(string: path, relativeTo: baseURL)?.absoluteURL
    }

    func publishedText(_ date: Date?) -> String {
        guard let date else {
            return "Недавно добавлено"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}
