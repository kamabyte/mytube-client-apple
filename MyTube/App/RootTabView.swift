import SwiftUI

struct RootTabView: View {
    @State private var selectedTab: RootTab = .videos
    @State private var tabResetIDs: [RootTab: Int] = [
        .videos: 0,
        .channels: 0,
        .statistics: 0
    ]

    var body: some View {
        TabView(selection: tabSelection) {
            Tab(RootTab.videos.title, systemImage: RootTab.videos.systemImage, value: .videos) {
                VideosScreen()
                    .id(tabResetID(for: .videos))
            }

            Tab(RootTab.channels.title, systemImage: RootTab.channels.systemImage, value: .channels) {
                ChannelsScreen()
                    .id(tabResetID(for: .channels))
            }

            Tab(RootTab.statistics.title, systemImage: RootTab.statistics.systemImage, value: .statistics) {
                StatisticsScreen()
                    .id(tabResetID(for: .statistics))
            }

        }
    }

    private var tabSelection: Binding<RootTab> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == selectedTab {
                    reset(tab: newValue)
                } else {
                    handleTabTransition(from: selectedTab, to: newValue)
                }

                selectedTab = newValue
            }
        )
    }

    private func tabResetID(for tab: RootTab) -> Int {
        tabResetIDs[tab, default: 0]
    }

    private func reset(tab: RootTab) {
        tabResetIDs[tab, default: 0] += 1
    }

    // Tabs that can push a detail screen go back to their root when you leave them,
    // so returning never drops you into a stale channel or player screen.
    private func handleTabTransition(from previousTab: RootTab, to newTab: RootTab) {
        switch previousTab {
            case .channels, .statistics:
                reset(tab: previousTab)
            case .videos:
                break
        }
    }
}

#Preview {
    RootTabView()
        .environment(AppEnvironment.bootstrap())
}
