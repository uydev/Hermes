import SwiftUI

struct ParticipantTileView: View {
    let tile: ParticipantTile

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let track = tile.videoTrack {
                LiveKitVideoView(track: track)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: tile.isCameraEnabled ? "video" : "video.slash")
                                .font(.system(size: 22))
                                .foregroundStyle(.secondary)
                            Text(tile.displayName)
                                .font(.headline)
                            Text(tile.isCameraEnabled ? "No video track" : "Camera off")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                    }
            }

            HStack(spacing: 8) {
                Text(tile.isLocal ? "\(tile.displayName) (You)" : tile.displayName)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)

                if tile.kind == .screenShare {
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: tile.isMicEnabled ? "mic.fill" : "mic.slash.fill")
                        .font(.caption)
                        .foregroundStyle(tile.isMicEnabled ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.red))

                    if tile.isSpeaking {
                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(10)
        }
        .aspectRatio(16.0/9.0, contentMode: .fit)
    }
}
