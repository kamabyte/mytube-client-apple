import Foundation

@Observable
final class AppEnvironment
{
    let catalogService: CatalogServicing

    init(catalogService: CatalogServicing)
    {
        self.catalogService = catalogService
    }

    static func bootstrap() -> AppEnvironment
    {
        AppEnvironment(catalogService: ApiCatalogService())
    }
}
