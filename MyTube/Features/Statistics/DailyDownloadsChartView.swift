import SwiftUI
import Charts

enum DailyMetric: String, CaseIterable, Identifiable {
    case count
    case volume

    var id: String { rawValue }

    var title: String {
        switch self {
            case .count: "Количество"
            case .volume: "Объём"
        }
    }
}

struct DailyDownloadsChartView: View {
    @Environment(\.isFocused) private var isFocused

    let data: [DailyStatistic]
    let metric: DailyMetric

    private var hasDownloads: Bool {
        data.contains { $0.videoCount > 0 }
    }

    var body: some View {
        if data.isEmpty || !hasDownloads {
            ContentUnavailableView(
                "Нет загрузок за 14 дней",
                systemImage: "calendar",
                description: Text("За последние две недели видео не скачивались.")
            )
            .frame(maxWidth: .infinity, minHeight: 320)
            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .strokeBorder(Color.white.opacity(isFocused ? 0.8 : 0.14), lineWidth: isFocused ? 3 : 1)
            )
            .animation(.easeOut(duration: 0.18), value: isFocused)
            .focusEffectDisabled()
        } else {
            chart
        }
    }

    private var chart: some View {
        Chart(data) { stat in
            BarMark(
                x: .value("День", stat.date, unit: .day),
                y: .value(metric.title, value(for: stat))
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(red: 0.35, green: 0.55, blue: 1.0), Color(red: 0.55, green: 0.40, blue: 0.95)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .cornerRadius(6)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 2)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.defaultDigits))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: 340)
        .padding(28)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(Color.white.opacity(isFocused ? 0.8 : 0.14), lineWidth: isFocused ? 3 : 1)
        )
        .animation(.easeOut(duration: 0.18), value: isFocused)
        .focusEffectDisabled()
    }

    private func value(for stat: DailyStatistic) -> Double {
        switch metric {
            case .count: Double(stat.videoCount)
            case .volume: stat.totalSizeGB
        }
    }
}

#Preview("Chart — count") {
    ScreenBackground {
        DailyDownloadsChartView(data: MockCatalogService.previewDailyStatistics, metric: .count)
            .padding(AppTheme.contentPadding)
    }
}

#Preview("Chart — empty") {
    ScreenBackground {
        DailyDownloadsChartView(
            data: MockCatalogService.previewDailyStatistics.map {
                DailyStatistic(id: $0.id, date: $0.date, videoCount: 0, totalSizeGB: 0)
            },
            metric: .count
        )
        .padding(AppTheme.contentPadding)
    }
}
