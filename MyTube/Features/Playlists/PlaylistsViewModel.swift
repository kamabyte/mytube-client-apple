import Foundation

@MainActor
@Observable
final class PlaylistsViewModel {
    private(set) var playlists: [Playlist] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func load(using service: CatalogServicing) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            playlists = try await service.fetchPlaylists()
        } catch {
            errorMessage = "Не удалось загрузить плейлисты."
        }

        isLoading = false
    }
}
