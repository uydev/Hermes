import Foundation
import LiveKit

enum ParticipantTileKind: Equatable {
    case camera
    case screenShare
}

struct ParticipantTile {
    let id: String
    let identity: String
    let displayName: String
    let isLocal: Bool
    let kind: ParticipantTileKind

    // LiveKit track to render (if available)
    let videoTrack: VideoTrack?

    let isSpeaking: Bool
    let isMicEnabled: Bool
    let isCameraEnabled: Bool
}
