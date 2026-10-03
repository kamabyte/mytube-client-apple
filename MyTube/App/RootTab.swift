import SwiftUI

enum RootTab: String, CaseIterable, Hashable, Identifiable {
    case videos
    case channels
    case statistics

    var id: String { rawValue }

    var title: String {
        switch self {
            case .videos: "Видео"
            case .channels: "Подписки"
            case .statistics: "Статистика"
        }
    }

    var systemImage: String {
        switch self {
            case .videos: "video.fill"
            case .channels: "dot.radiowaves.left.and.right"
            case .statistics: "chart.bar.fill"
        }
    }
}
