import Foundation

struct Channel: Identifiable, Hashable {
    let id: UUID
    let sourceID: String
    let name: String
    let handle: String
    let description: String
    let avatarURL: URL?
    let subscribersText: String
    let accentColorHex: String
    /// Downloaded videos (`videos_count`).
    var downloadedCount: Int? = nil
    /// The whole catalog, downloaded or not (`catalog_count`).
    var catalogCount: Int? = nil
    /// Keeps a catalog only: videos are downloaded when someone asks.
    var isOnDemand: Bool = false

    /// "91 видео", "5 видео · ещё 500 не скачано", "505 видео в каталоге" — as in the web client.
    var videoCountsText: String? {
        guard let catalogCount else {
            return downloadedCount.map { "\($0) видео" }
        }

        let downloaded = downloadedCount ?? 0
        let notDownloaded = max(catalogCount - downloaded, 0)

        if notDownloaded == 0 {
            return "\(downloaded) видео"
        }

        if downloaded == 0 {
            return "\(notDownloaded) видео в каталоге"
        }

        return "\(downloaded) видео · ещё \(notDownloaded) не скачано"
    }
}
