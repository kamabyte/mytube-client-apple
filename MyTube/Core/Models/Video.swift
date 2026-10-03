import Foundation

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
}
