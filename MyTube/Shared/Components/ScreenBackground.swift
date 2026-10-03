import SwiftUI

struct ScreenBackground<Content: View>: View {
    @ViewBuilder private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppTheme.pageGradient
                .ignoresSafeArea()

            content
        }
    }
}
