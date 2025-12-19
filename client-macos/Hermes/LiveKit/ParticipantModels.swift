import Foundation
import LiveKit

struct ParticipantTile: Identifiable {
    let id: String
    let identity: String
    let displayName: String
    let isLocal: Bool

    // LiveKit track to render (if available)
    let videoTrack: VideoTrack?

    let isSpeaking: Bool
    let isMicEnabled: Bool
    let isCameraEnabled: Bool
}
