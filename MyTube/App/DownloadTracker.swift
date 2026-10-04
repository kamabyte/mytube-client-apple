import Foundation

/// The freshest copy of videos whose download state changed in this session (requested,
/// cancelled, finished). Screens keep the lists they loaded; cards and the video route read
/// through `current(_:)`, so a badge updates the moment you come back from the download screen.
@MainActor
@Observable
final class DownloadTracker {
    private var latest: [UUID: Video] = [:]

    func current(_ video: Video) -> Video {
        latest[video.id] ?? video
    }

    func update(_ video: Video) {
        latest[video.id] = video
    }
}
