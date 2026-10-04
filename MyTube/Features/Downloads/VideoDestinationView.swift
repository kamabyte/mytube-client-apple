import SwiftUI

/// Where a selected video leads: the player for a downloaded one, the download screen otherwise.
/// Decided once, when the screen opens: if the download finishes while you're on it, the screen
/// offers "Смотреть" instead of starting playback on its own.
struct VideoDestinationView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var showsPlayer: Bool?

    let video: Video

    var body: some View {
        let current = environment.downloads.current(video)

        Group {
            if showsPlayer ?? current.isPlayable {
                PlayerScreen(video: current)
            } else {
                VideoDownloadScreen(video: current) {
                    showsPlayer = true
                }
            }
        }
        .onAppear {
            if showsPlayer == nil {
                showsPlayer = current.isPlayable
            }
        }
    }
}
