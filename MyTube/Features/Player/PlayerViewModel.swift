import AVKit
import Foundation

@MainActor
@Observable
final class PlayerViewModel {
    private final class PlaybackObserverStorage {
        var token: NSObjectProtocol?

        deinit {
            if let token {
                NotificationCenter.default.removeObserver(token)
            }
        }
    }

    private(set) var video: Video
    let player: AVPlayer
    let queue: [Video]
    var isAutoplayEnabled: Bool
    private var hasStartedPlayback = false
    private let playbackObserverStorage = PlaybackObserverStorage()

    init(video: Video, queue: [Video] = [], isAutoplayEnabled: Bool = true) {
        self.video = video
        self.queue = queue.isEmpty ? [video] : queue
        self.isAutoplayEnabled = isAutoplayEnabled
        self.player = AVPlayer(playerItem: Self.makePlayerItem(for: video))
        self.player.audiovisualBackgroundPlaybackPolicy = .automatic
        self.player.allowsExternalPlayback = true
        observePlaybackCompletion()
    }

    func startPlaybackIfNeeded() {
        guard hasStartedPlayback == false else {
            player.play()
            return
        }

        hasStartedPlayback = true
        player.playImmediately(atRate: 1.0)
    }

    func pausePlayback() {
        player.pause()
    }

    var currentQueueIndex: Int? {
        queue.firstIndex(of: video)
    }

    var hasNextVideo: Bool {
        guard let currentQueueIndex else { return false }
        return queue.indices.contains(currentQueueIndex + 1)
    }

    func playNextIfAvailable() {
        guard let currentQueueIndex, queue.indices.contains(currentQueueIndex + 1) else {
            return
        }

        let nextVideo = queue[currentQueueIndex + 1]
        video = nextVideo
        player.replaceCurrentItem(with: Self.makePlayerItem(for: nextVideo))
        hasStartedPlayback = true
        player.playImmediately(atRate: 1.0)
    }

    private func observePlaybackCompletion() {
        playbackObserverStorage.token = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let endedItemID = notification.object.map { ObjectIdentifier($0 as AnyObject) }

            Task { @MainActor [weak self] in
                guard let self else { return }
                guard let currentItem = self.player.currentItem, endedItemID == ObjectIdentifier(currentItem) else {
                    return
                }

                if self.isAutoplayEnabled {
                    self.playNextIfAvailable()
                }
            }
        }
    }

    deinit {
        player.pause()
    }

    private static func makePlayerItem(for video: Video) -> AVPlayerItem {
        let item = AVPlayerItem(url: video.streamURL)
        item.externalMetadata = [
            metadataItem(identifier: .commonIdentifierTitle, value: video.title),
            metadataItem(identifier: .commonIdentifierDescription, value: video.description ?? ""),
            metadataItem(identifier: .quickTimeMetadataGenre, value: video.channelName)
        ]
        return item
    }

    private static func metadataItem(identifier: AVMetadataIdentifier, value: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as NSString
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }
}
