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
}
