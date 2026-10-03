import Foundation

/// Shared formatting for the Statistics screen. Kept out of the views so the
/// `NumberFormatter` is created once instead of on every redraw.
enum StatisticsFormatter {
    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "\u{2009}"
        return formatter
    }()

    static func number(_ value: Int) -> String {
        decimalFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func size(gb: Double) -> String {
        if gb >= 1_024 {
            return String(format: "%.1f ТБ", gb / 1_024)
        }

        if gb >= 1 {
            return String(format: "%.1f ГБ", gb)
        }

        return "\(Int((gb * 1_024).rounded())) МБ"
    }

    static func durationHours(_ hours: Double) -> String {
        if hours >= 1_000 {
            return String(format: "%.1f тыс. ч", hours / 1_000)
        }

        return String(format: "%.0f ч", hours)
    }
}
