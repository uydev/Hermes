import Foundation
import Combine
import LiveKit

@MainActor
final class LiveKitMeetingViewModel: ObservableObject, RoomDelegate {
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

    @Published private(set) var participantTiles: [ParticipantTile] = []
    @Published private(set) var chatMessages: [ChatMessage] = []

    func connectIfNeeded(join: RoomJoinResponse) async {
        if case .connected = state { return }
        if case .connecting = state { return }

        state = .connecting

        do {
            // Request AV permissions up-front so failures are explicit (vs. opaque "Cancelled").
            let cameraOk = await AVPermissions.requestCamera()
            if !cameraOk {
                state = .failed("Camera permission denied. Enable Camera for Hermes in System Settings → Privacy & Security → Camera.")
                return
            }

            let micOk = await AVPermissions.requestMicrophone()
            if !micOk {
                state = .failed("Microphone permission denied. Enable Microphone for Hermes in System Settings → Privacy & Security → Microphone.")
                return
            }

            let room = Room(delegate: self)
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
            rebuildParticipantTiles()
            state = .connected
        } catch {
            if error is CancellationError {
                state = .failed("Cancelled. This is usually caused by missing permissions or the view lifecycle cancelling the connect task.")
                return
            }
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
        await room?.disconnect()

        room = nil
        localVideoTrack = nil
        localAudioTrack = nil
        isMicEnabled = true
        isCameraEnabled = true
        participantTiles = []
        chatMessages = []
        state = .idle
    }

    // MARK: - Participants

    private func rebuildParticipantTiles() {
        guard let room else {
            participantTiles = []
            return
        }

        var tiles: [ParticipantTile] = []

        // Local
        let localIdentity = room.localParticipant.identity?.stringValue ?? "local"
        let localName = room.localParticipant.name ?? "You"
        let localTile = ParticipantTile(
            id: "local:\(localIdentity)",
            identity: localIdentity,
            displayName: localName,
            isLocal: true,
            videoTrack: localVideoTrack,
            isSpeaking: room.localParticipant.isSpeaking,
            isMicEnabled: isMicEnabled,
            isCameraEnabled: isCameraEnabled
        )
        tiles.append(localTile)

        // Remote participants
        for (_, participant) in room.remoteParticipants {
            let identity = participant.identity?.stringValue ?? participant.sid?.stringValue ?? "unknown"
            let name = participant.name ?? identity

            // Pick first subscribed video track (MVP)
            let videoTrack: VideoTrack? = participant.videoTracks
                .compactMap { $0.track as? VideoTrack }
                .first

            let micEnabled = participant.audioTracks.contains { $0.track != nil }
            let camEnabled = participant.videoTracks.contains { $0.track != nil }

            tiles.append(
                ParticipantTile(
                    id: "remote:\(participant.sid)",
                    identity: identity,
                    displayName: name,
                    isLocal: false,
                    videoTrack: videoTrack,
                    isSpeaking: participant.isSpeaking,
                    isMicEnabled: micEnabled,
                    isCameraEnabled: camEnabled
                )
            )
        }

        // Prefer stable order: local first, then by name
        participantTiles = [tiles.first].compactMap { $0 } + tiles.dropFirst().sorted { $0.displayName < $1.displayName }
    }

    // MARK: - Chat (LiveKit data messages)

    func sendChat(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let room else { return }

        let sender = room.localParticipant.name ?? room.localParticipant.identity?.stringValue ?? "You"
        let wire = ChatWireMessage(type: "chat", sender: sender, text: trimmed, ts: Date().timeIntervalSince1970)
        guard let data = try? JSONEncoder().encode(wire) else { return }

        do {
            let options = DataPublishOptions(topic: "chat", reliable: true)
            try await room.localParticipant.publish(data: data, options: options)
            chatMessages.append(ChatMessage(id: UUID(), sender: sender, text: trimmed, timestamp: Date(), isLocal: true))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - RoomDelegate

    nonisolated func room(_ room: Room, didUpdateConnectionState connectionState: ConnectionState, from oldConnectionState: ConnectionState) {
        Task { @MainActor in rebuildParticipantTiles() }
    }

    nonisolated func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        Task { @MainActor in rebuildParticipantTiles() }
    }

    nonisolated func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        Task { @MainActor in rebuildParticipantTiles() }
    }

    nonisolated func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        Task { @MainActor in rebuildParticipantTiles() }
    }

    nonisolated func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) {
        Task { @MainActor in rebuildParticipantTiles() }
    }

    nonisolated func room(_ room: Room, participant: RemoteParticipant?, didReceiveData data: Data, forTopic topic: String, encryptionType: EncryptionType) {
        guard topic == "chat" else { return }
        Task { @MainActor in
            if let wire = try? JSONDecoder().decode(ChatWireMessage.self, from: data), wire.type == "chat" {
                chatMessages.append(ChatMessage(id: UUID(), sender: wire.sender, text: wire.text, timestamp: Date(timeIntervalSince1970: wire.ts), isLocal: false))
                return
            }

            let sender = participant?.name ?? participant?.identity?.stringValue ?? "Participant"
            let text = String(data: data, encoding: .utf8) ?? "<binary data>"
            chatMessages.append(ChatMessage(id: UUID(), sender: sender, text: text, timestamp: Date(), isLocal: false))
        }
    }
}
