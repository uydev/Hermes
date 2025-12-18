import SwiftUI
import LiveKit

/// SwiftUI wrapper for LiveKit's VideoView (macOS).
struct LiveKitVideoView: NSViewRepresentable {
    var track: VideoTrack?

    func makeNSView(context: Context) -> VideoView {
        let view = VideoView()
        view.mirrorMode = .auto
        view.track = track
        return view
    }

    func updateNSView(_ nsView: VideoView, context: Context) {
        nsView.track = track
    }
}
