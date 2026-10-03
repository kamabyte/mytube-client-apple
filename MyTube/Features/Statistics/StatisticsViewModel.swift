import Foundation

@MainActor
@Observable
final class StatisticsViewModel {
    enum SectionState<Value> {
        case loading
        case loaded(Value)
        case failed

        var isLoaded: Bool {
            if case .loaded = self { return true }
            return false
        }
    }

    private(set) var summary: SectionState<StatisticsSummary> = .loading
    private(set) var channels: SectionState<[ChannelStatistic]> = .loading
    private(set) var daily: SectionState<[DailyStatistic]> = .loading
    private(set) var isRefreshing = false

    /// Re-entering the tab retries whatever is still missing instead of leaving
    /// a failed section stuck behind its "Повторить" button.
    private var needsLoad: Bool {
        !summary.isLoaded || !channels.isLoaded || !daily.isLoaded
    }

    func load(using service: CatalogServicing) async {
        guard needsLoad else { return }
        await refresh(using: service)
    }

    func refresh(using service: CatalogServicing) async {
        guard !isRefreshing else { return }

        isRefreshing = true

        // Sections that already have data keep showing it while the refresh runs:
        // blanking them out would also drop tvOS focus back to the top of the screen.
        if !summary.isLoaded { summary = .loading }
        if !channels.isLoaded { channels = .loading }
        if !daily.isLoaded { daily = .loading }

        async let summaryLoad: Void = loadSummary(using: service)
        async let channelsLoad: Void = loadChannels(using: service)
        async let dailyLoad: Void = loadDaily(using: service)

        await summaryLoad
        await channelsLoad
        await dailyLoad

        isRefreshing = false
    }

    func retrySummary(using service: CatalogServicing) async {
        summary = .loading
        await loadSummary(using: service)
    }

    func retryChannels(using service: CatalogServicing) async {
        channels = .loading
        await loadChannels(using: service)
    }

    func retryDaily(using service: CatalogServicing) async {
        daily = .loading
        await loadDaily(using: service)
    }

    private func loadSummary(using service: CatalogServicing) async {
        do {
            summary = .loaded(try await Self.retrying { try await service.fetchStatisticsSummary() })
        } catch {
            summary = .failed
        }
    }

    private func loadChannels(using service: CatalogServicing) async {
        do {
            channels = .loaded(try await Self.retrying { try await service.fetchChannelStatistics() })
        } catch {
            channels = .failed
        }
    }

    private func loadDaily(using service: CatalogServicing) async {
        do {
            daily = .loaded(try await Self.retrying { try await service.fetchDailyStatistics() })
        } catch {
            daily = .failed
        }
    }

    /// Statistics endpoints have no mock fallback, so a single flaky request would
    /// otherwise park the whole section on an error card. Retries with a 1s / 2s backoff.
    private static func retrying<Value>(
        attempts: Int = 3,
        operation: () async throws -> Value
    ) async throws -> Value {
        for attempt in 1...attempts {
            do {
                return try await operation()
            } catch {
                guard attempt < attempts else { throw error }
                try Task.checkCancellation()
                try await Task.sleep(for: .seconds(Double(1 << (attempt - 1))))
            }
        }

        throw CancellationError()
    }
}
