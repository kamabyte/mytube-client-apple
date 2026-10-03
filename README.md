# MyTube для Apple TV

Клиент для tvOS к [MyTube](https://github.com/kamabyte/mytube-api) — своей медиатеке
YouTube-видео на домашнем сервере. SwiftUI, tvOS 26.2, без сторонних зависимостей.

Вкладки: **Видео**, **Каналы** (список и страница канала), **Статистика**.
Плеер на `AVPlayer` с очередью и автовоспроизведением следующего видео,
метаданные для Now Playing на tvOS.

## Сборка

1. Скопируйте настройки и впишите свои значения:

   ```sh
   cp Config/Local.xcconfig.example Config/Local.xcconfig
   ```

   | Параметр | Что это |
   |---|---|
   | `DEVELOPMENT_TEAM` | ваш Team ID в Apple Developer (Xcode → Settings → Accounts) |
   | `PRODUCT_BUNDLE_IDENTIFIER` | свой bundle ID, например `com.yourname.MyTube` |
   | `MYTUBE_API_BASE_URL` | адрес сервера MyTube API; `//` в xcconfig пишется как `/$()/` |

   `Config/Local.xcconfig` в `.gitignore` — личные значения в репозиторий не попадают.
   Без него сборка берёт значения по умолчанию из `Config/Base.xcconfig`.

2. Откройте `MyTube.xcodeproj` в Xcode и запустите на Apple TV или в симуляторе. Или:

   ```sh
   xcodebuild -project MyTube.xcodeproj -scheme MyTube \
     -destination 'generic/platform=tvOS Simulator' build
   ```

Сервер обычно в локальной сети и без HTTPS, поэтому в `Info.plist` разрешён HTTP
(`NSAllowsArbitraryLoads`). Если API недоступен, приложение показывает демо-данные
из `MockCatalogService`.

## Устройство

| Папка | Что внутри |
|---|---|
| `MyTube/App` | запуск приложения, вкладки, контейнер зависимостей `AppEnvironment` |
| `MyTube/Core/Models` | модели: `Video`, `Channel`, `Playlist`, статистика |
| `MyTube/Core/Services` | `CatalogServicing`: `ApiCatalogService` (MyTube API) и `MockCatalogService` |
| `MyTube/Core/DesignSystem` | цвета, отступы, скругления — `AppTheme` |
| `MyTube/Features/*` | экраны и их view model: видео, каналы, плейлисты, библиотека, статистика, плеер |
| `MyTube/Shared/Components` | общие компоненты интерфейса для TV |
| `Config/` | настройки сборки (`Base.xcconfig` + локальный `Local.xcconfig`) |
| `Tools/` | генератор иконок и Top Shelf |

Проект использует синхронизированную папку Xcode: новые файлы в `MyTube/`
подключаются к таргету сами, `project.pbxproj` править не нужно.

## Лицензия

[MIT](LICENSE)
