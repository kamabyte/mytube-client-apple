import Foundation

struct StatisticsSummary: Hashable {
    let totalVideos: Int
    let totalChannels: Int
    let totalVideoSizeGB: Double
    let totalDurationHours: Double
    let videosInProgress: Int
}

struct ChannelStatistic: Identifiable, Hashable {
    let id: UUID
    let sourceID: String
    let channelTitle: String
    let videoCount: Int
    let totalSizeGB: Double
}

extension ChannelStatistic {
    /// The statistics endpoint only returns the channel id and title, so the `Channel`
    /// built here carries just what `ChannelDetailScreen` needs: `sourceID` for requests
    /// and `name` for the header. Avatar/handle stay empty and the detail header hides them.
    func makeChannel() -> Channel {
        Channel(
            id: id,
            sourceID: sourceID,
            name: channelTitle,
            handle: "",
            description: "",
            avatarURL: nil,
            subscribersText: "",
            accentColorHex: "#3B82F6"
        )
    }
}

struct DailyStatistic: Identifiable, Hashable {
    let id: String
    let date: Date
    let videoCount: Int
    let totalSizeGB: Double
}
