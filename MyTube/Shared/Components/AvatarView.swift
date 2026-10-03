import SwiftUI

struct AvatarView: View {
    let url: URL?
    let size: CGFloat
    let placeholder: String

     init(
        url: URL?,
        size: CGFloat = 50,
        placeholder: String = "person.fill"
    ) {
        self.url = url
        self.size = size
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let url = url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderView
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(radius: 3)
    }
    private var placeholderView: some View {
        Image(systemName: placeholder)
            .font(.system(size: size * 0.5))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Color.white.opacity(0.2))
    }
}
