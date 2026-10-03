import AVKit
import SwiftUI
import UIKit

struct PlayerScreen: View {
    @State private var viewModel: PlayerViewModel

    init(video: Video, queue: [Video] = []) {
        _viewModel = State(initialValue: PlayerViewModel(video: video, queue: queue))
    }

    var body: some View {
        TVPlayerContainer(viewModel: viewModel)
            .background(Color.black)
            .ignoresSafeArea(edges: .all)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.startPlaybackIfNeeded()
        }
        .onDisappear {
            viewModel.pausePlayback()
        }
    }
}

private struct TVPlayerContainer: UIViewControllerRepresentable {
    let viewModel: PlayerViewModel

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = viewModel.player
        controller.showsPlaybackControls = true
        controller.restoresFocusAfterTransition = true
        controller.allowsPictureInPicturePlayback = true
        controller.videoGravity = .resizeAspect
        controller.view.backgroundColor = .black
        configurePlayerUI(controller)
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player !== viewModel.player {
            controller.player = viewModel.player
        }

        configurePlayerUI(controller)
    }

    private func configurePlayerUI(_ controller: AVPlayerViewController) {
        #if os(tvOS)
        controller.customInfoViewControllers = [makeInfoViewController()]
        #endif
    }

    private func makeInfoViewController() -> UIViewController {
        let hostingController = UIHostingController(rootView: PlayerInfoView(viewModel: viewModel))
        hostingController.title = "Подробнее"
        hostingController.view.backgroundColor = .clear
        hostingController.preferredContentSize = CGSize(width: 760, height: 280)
        return hostingController
    }
}

private struct PlayerInfoView: View {
    let viewModel: PlayerViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.video.title)
                    .font(.title.bold())
                    .lineLimit(2)

                Text("\(viewModel.video.channelName) • \(viewModel.video.publishedText)")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                if let description = viewModel.video.description, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }
            }

            Toggle(isOn: $viewModel.isAutoplayEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Автовоспроизведение")
                        .font(.headline)

                    Text(viewModel.hasNextVideo ? "Автоматически воспроизводить следующее видео." : "Следующего видео нет.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(viewModel.hasNextVideo == false)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview {
    PlayerScreen(video: MockCatalogService.previewVideos[0])
}
