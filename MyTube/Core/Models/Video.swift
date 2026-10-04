import Foundation

/// Where a video is on its way into the library — `App\Support\DownloadState` on the server.
enum DownloadState: String, Hashable, Sendable {
    /// In the catalog, nobody asked for it yet.
    case available
    /// Waiting for the worker: requested, or its channel downloads everything.
    case queued
    case downloading
    case downloaded
    /// YouTube won't serve it (removed, private, region-locked).
    case unavailable
}

struct Video: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let description: String?
    let thumbnailURL: URL?
    let durationSeconds: Int?
    let streamURL: URL
    let channelID: UUID
    let channelName: String
    let publishedText: String
    /// Server id — what the download endpoints take. Empty for mock data.
    var sourceID: String = ""
    var downloadState: DownloadState = .downloaded
    /// Someone asked for it (vs. queued because its channel downloads everything): only a request can be cancelled.
    var isDownloadRequested: Bool = false

    var isPlayable: Bool {
        downloadState == .downloaded
    }
}
