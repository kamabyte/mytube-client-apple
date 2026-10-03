import SwiftUI

@main
struct MyTubeApp: App
{
    @State private var environment = AppEnvironment.bootstrap()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(environment)
        }
    }
}
