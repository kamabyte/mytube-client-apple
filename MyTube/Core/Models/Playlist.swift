import Foundation

struct Playlist: Identifiable, Hashable {
    let id: UUID
    let title: String
    let summary: String
    let artworkURL: URL?
    let itemCount: Int
    let curator: String
    let videos: [Video]
}
