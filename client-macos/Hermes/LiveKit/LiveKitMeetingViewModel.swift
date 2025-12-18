import Foundation
import Combine
import LiveKit

@MainActor
final class LiveKitMeetingViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case connecting
        case connected
        case failed(String)
    }

    @Published private(set) var state: State = .idle

    @Published private(set) var room: Room?
    @Published private(set) var localVideoTrack: LocalVideoTrack?
    @Published private(set) var localAudioTrack: LocalAudioTrack?

    @Published private(set) var isMicEnabled: Bool = true
    @Published private(set) var isCameraEnabled: Bool = true

    func connectIfNeeded(join: RoomJoinResponse) async {
        if case .connected = state { return }
        if case .connecting = state { return }

        state = .connecting

        do {
            let room = Room()
            self.room = room

            // Connect
            try await room.connect(url: join.liveKitUrl, token: join.liveKitToken)

            // Create local tracks
            let video = LocalVideoTrack.createCameraTrack()
            let audio = LocalAudioTrack.createTrack()

            self.localVideoTrack = video
            self.localAudioTrack = audio

            // Publish
            try await room.localParticipant.publish(videoTrack: video)
            try await room.localParticipant.publish(audioTrack: audio)

            isMicEnabled = true
            isCameraEnabled = true
            state = .connected
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func toggleMic() async {
        guard let room else { return }
        do {
            let enable = !isMicEnabled
            try await room.localParticipant.setMicrophone(enabled: enable)
            isMicEnabled = enable
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func toggleCamera() async {
        guard let room else { return }
        do {
            let enable = !isCameraEnabled
            try await room.localParticipant.setCamera(enabled: enable)
            isCameraEnabled = enable
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func disconnect() async {
        do {
            try await room?.disconnect()
        } catch {
            // ignore
        }

        room = nil
        localVideoTrack = nil
        localAudioTrack = nil
        isMicEnabled = true
        isCameraEnabled = true
        state = .idle
    }
}
