import SwiftUI

struct LibraryScreen: View {
    private let quickActions: [(title: String, subtitle: String, icon: String)] = [
        ("Смотреть позже", "Очередь видео для просмотра на большом экране", "clock.fill"),
        ("Продолжить просмотр", "Вернуться к незавершённым видео", "play.rectangle.on.rectangle.fill"),
        ("Понравившиеся", "Сохранённые и избранные видео", "hand.thumbsup.fill"),
        ("Загрузки", "Контент для просмотра без сети", "arrow.down.circle.fill")
    ]

    private let futureModules: [String] = [
        "Поиск и голосовые запросы",
        "Подписки и ранжирование ленты",
        "История просмотров и точки возобновления",
        "Профили и родительский контроль",
        "Полки и рекомендации с сервера"
    ]

    private let columns = [
        GridItem(.flexible(minimum: 420), spacing: 28),
        GridItem(.flexible(minimum: 420), spacing: 28)
    ]

    var body: some View {
        NavigationStack {
            ScreenBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 34) {
                        Text("Библиотека")
                            .font(.system(size: 50, weight: .bold, design: .rounded))

                        LazyVGrid(columns: columns, spacing: 28) {
                            ForEach(quickActions, id: \.title) { item in
                                VStack(alignment: .leading, spacing: 14) {
                                    Label(item.title, systemImage: item.icon)
                                        .font(.title3.weight(.semibold))

                                    Text(item.subtitle)
                                        .font(.body)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                                .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
                                .padding(24)
                                .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 24))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                                )
                            }
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Text("Что добавить дальше")
                                .font(.title2.weight(.semibold))

                            ForEach(futureModules, id: \.self) { module in
                                Text("• \(module)")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                    }
                    .screenContentPadding()
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}
