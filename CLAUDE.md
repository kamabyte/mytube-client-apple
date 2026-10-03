# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

tvOS SwiftUI client for MyTube, a YouTube-like app. Deployment target **tvOS 26.2**, Swift 5.0, `TARGETED_DEVICE_FAMILY = 3` (tvOS only — do not add iOS/macOS code paths). No Swift Package dependencies, no test target.

## Build & run

No custom scripts. Use Xcode or `xcodebuild` directly:

```bash
# Build for Apple TV simulator
xcodebuild -project MyTube.xcodeproj -scheme MyTube -sdk appletvsimulator build

# Build for device
xcodebuild -project MyTube.xcodeproj -scheme MyTube -sdk appletvos build

# List available simulators to pick a -destination
xcrun simctl list devicetypes | grep -i tv
```

The Xcode project uses a `PBXFileSystemSynchronizedRootGroup` on the `MyTube/` folder — new Swift files added anywhere under `MyTube/` are picked up automatically. **Do not edit `project.pbxproj` to register files.**

## Architecture

### Dependency injection
`AppEnvironment` (in `App/AppEnvironment.swift`) is an `@Observable` container created once in `MyTubeApp` and injected via SwiftUI's `.environment(...)`. Screens read it with `@Environment(AppEnvironment.self)`. Currently holds only `catalogService: CatalogServicing`. Bootstrap wires `ApiCatalogService()` by default.

### Catalog layer — this is the important one
`CatalogServicing` (Core/Services) is the single protocol the UI talks to: `fetchChannels(page:)`, `fetchPlaylists`, `fetchVideos(for:page:sort:)`. Two implementations:

- **`ApiCatalogService`** — real backend; the address comes from Info.plist `MyTubeAPIBaseURL` ← build setting `MYTUBE_API_BASE_URL` (`Config/Base.xcconfig`, overridden in the gitignored `Config/Local.xcconfig`). Wire format is **JSON:API-ish Laravel**: `page[number]`, `page[size]`, `filter[...]`, `sort`, `include`, `fields[...]`. Response envelope is `{ data, meta: { current_page, last_page }, links: { next } }` — see `PaginatedResponse`. Takes an optional `fallbackService` (defaults to `MockCatalogService`) and transparently falls back on any network/decoding error. When adding endpoints, extend `Endpoint` and the nested `*Response` types; keep the `toDomain(...)` conversion pattern.
- **`MockCatalogService`** — hardcoded sample data. Its `preview*` statics are also used in `#Preview` blocks.

API IDs arrive as strings or ints; `APIIdentifier.stableUUID(namespace:)` deterministically folds them into a UUID so domain models can use `UUID`. The `channelID` on a `Video` uses namespace `"channel"`, the video's own `id` uses `"video"` — keep these consistent if you add new resources.

### View models
All view models are `@MainActor @Observable final class` (Swift's Observation framework, **not** `ObservableObject`/Combine). Screens own them via `@State`. Standard shape: `private(set) var` state, `isLoading` gate, `errorMessage: String?`, and async `load(using: CatalogServicing)` method that takes the service from the environment (rather than capturing it in init). Pagination view models (e.g. `ChannelDetailViewModel`) track `currentPage` / `hasMoreVideos` and expose `loadMoreIfNeeded(currentVideo:...)` that triggers when within 6 items of the end.

### Feature layout
Each feature under `MyTube/Features/<Name>/` is a screen + view model pair (sometimes plus a detail screen). `Features/Videos`, `Features/Channels` (list + detail), `Features/Playlists`, `Features/Library`, `Features/Player`. `Features/VideoPlayer/` is currently empty. `RootTabView` drives tab selection and re-renders a tab's content by bumping an `.id(...)` reset key — tapping the currently-selected tab resets that tab's stack; switching channels→videos also resets channels.

### Player
`PlayerViewModel` wraps `AVPlayer` with a `queue: [Video]` and `isAutoplayEnabled`. On `AVPlayerItemDidPlayToEndTime` it advances to the next queue item. `PlaybackObserverStorage` is a tiny class that removes the NotificationCenter observer in `deinit` (the view model itself can't be `deinit`-used for that cleanly under `@MainActor`). `AVPlayerItem`s get `externalMetadata` (title/description/channel) for the tvOS Now-Playing UI.

### Design system
`Core/DesignSystem/AppTheme.swift` centralizes colors, gradients, corner radii, and spacing. Use these tokens rather than hardcoding values in views.

### Shared components
`Shared/Components/` holds reusable tvOS-focus-aware UI: `VideoCardView`, `ChannelCardView`, `HeroBannerView`, `AvatarView`, `ScreenBackground`. Prefer extending these over duplicating card chrome.

## Conventions

- Swift Observation (`@Observable`), not Combine/`ObservableObject`.
- Navigation via `NavigationStack` + `.navigationDestination(for: Video.self)`; routes are keyed on value-type models conforming to `Hashable`.
- Service errors are caught at the view-model boundary and surfaced as a user-facing `errorMessage` string, not rethrown into views.
- Some user-facing strings are Russian (e.g. `"Загрузка видео..."` in `VideosScreen`) — the app is partially localized ad-hoc rather than via `.strings` files. Match existing language when editing a screen; don't silently translate.
- Brace style in this codebase is mixed (Allman on some types, K&R on others). Match the surrounding file.

## Notion Integration

This project is wired into the [`claude-notion-pipeline`] — a cron orchestrator that picks tasks from a shared Notion database and walks them through automated planning → human review → implementation → merge.

- **Project Slug**: `mytube-apple-client`  ← value of the Notion `Project` select on tasks belonging to this repo
- **Pipeline statuses (happy path)**:
  `Draft → To Do → Planning → Plan Ready → Plan Approved → In Progress → In Review → Done`
- **Revision loops**:
  - `Plan Ready → Plan Revision → Planning → Plan Ready` — request changes to a plan
  - `In Review → Changes Requested → In Progress → In Review` — request changes to a PR
- `Blocked` is a parking lot, can be entered from any active stage.

### Who moves the status

| Transition | Mover |
| --- | --- |
| Draft → To Do | human (Notion UI) |
| To Do → Planning | orchestrator (claims the task) |
| Planning → Plan Ready | Claude (`/plan-task` finishes) |
| Plan Ready → Plan Approved | human (after reviewing the plan) |
| **Plan Ready → Plan Revision** | human (after leaving Notion comments asking for changes) |
| **Plan Revision → Planning** | orchestrator (claims for re-plan) |
| Plan Approved → In Progress | orchestrator (claims the task) |
| In Progress → In Review | Claude (`/work-task` finishes, PR opened) |
| **In Review → Changes Requested** | human (after leaving PR comments asking for changes) |
| **Changes Requested → In Progress** | orchestrator (claims for re-work) |
| In Review → Done | orchestrator (detects merged PR) |
| any → Blocked | Claude / orchestrator on failure |

### Pipeline commands

User-level (`~/.claude/commands/`): `plan-task`, `work-task`, `submit-task`, `complete-task`, `pick-task`, `fix-bug`.

The orchestrator only invokes `plan-task` and `work-task`. The rest are manual helpers for interactive Claude Code use.

### Plan format

The plan lives in the page body under the `## 📋 План реализации` heading.

- If you want to **edit the plan yourself**: just edit it inline in `Plan Ready`, then move to `Plan Approved`. Claude will use the latest version when work begins.
- If you want **Claude to revise**: leave Notion comments on the parts you want changed (use the comment sidebar or inline thread on a specific block), then move the task `Plan Ready → Plan Revision`. Next orchestrator cycle, Claude reads the comments, writes a new revision (the previous version goes into a collapsible `<details>` block under "История планов"), and lands the task back in `Plan Ready`.

### Code-review loop

Same idea on the implementation side. Leave PR review comments on GitHub. To ask Claude to address them, move the task `In Review → Changes Requested`. The orchestrator will run `/work-task` again; Claude pulls the branch, reads the review comments via `gh`, addresses them with additional commits on the same branch (no force-push, no new PR), and lands the task back in `In Review`. Claude does NOT post replies on review threads — the new commits are the signal.
