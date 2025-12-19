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

    @Published private(set) var isScreenSharing: Bool = false
    private var screenSharePublication: LocalTrackPublication?
    private var screenShareTrack: LocalVideoTrack?

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
            rebuildParticipantTiles()
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
            rebuildParticipantTiles()
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
        isScreenSharing = false
        screenSharePublication = nil
        screenShareTrack = nil
        participantTiles = []
        chatMessages = []
        state = .idle
    }

    // MARK: - Screen share (macOS)

    func startScreenShare(source: MacOSScreenCaptureSource) async {
        guard let room else { return }

        if !ProcessInfo.processInfo.isOperatingSystemAtLeast(
            OperatingSystemVersion(majorVersion: 12, minorVersion: 3, patchVersion: 0)
        ) {
            state = .failed("Screen sharing requires macOS 12.3 or later.")
            return
        }

        do {
            // Stop existing share first (if any)
            if let pub = screenSharePublication {
                try await room.localParticipant.unpublish(publication: pub)
            }

            let options = ScreenShareCaptureOptions(
                dimensions: .h1080_169,
                fps: 15,
                showCursor: true,
                appAudio: false,
                includeCurrentApplication: false
            )

            // Create screen share track (source is marked as .screenShareVideo internally)
            let track: LocalVideoTrack
            if #available(macOS 12.3, *) {
                track = LocalVideoTrack.createMacOSScreenShareTrack(source: source, options: options)
            } else {
                state = .failed("Screen sharing requires macOS 12.3 or later.")
                return
            }

            // Publish
            let pub = try await room.localParticipant.publish(videoTrack: track)

            screenShareTrack = track
            screenSharePublication = pub
            isScreenSharing = true

            rebuildParticipantTiles()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func stopScreenShare() async {
        guard let room else { return }
        guard let pub = screenSharePublication else { return }
        do {
            try await room.localParticipant.unpublish(publication: pub)
        } catch {
            // ignore
        }
        screenSharePublication = nil
        screenShareTrack = nil
        isScreenSharing = false
        rebuildParticipantTiles()
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

        // Local screenshare (as separate tile)
        if let screenTrack = screenShareTrack, isScreenSharing {
            tiles.append(
                ParticipantTile(
                    id: "local:\(localIdentity):screenshare",
                    identity: localIdentity,
                    displayName: "\(localName) — Screen",
                    isLocal: true,
                    videoTrack: screenTrack,
                    isSpeaking: false,
                    isMicEnabled: false,
                    isCameraEnabled: true
                )
            )
        }

        // Remote participants
        for (_, participant) in room.remoteParticipants {
            let identity = participant.identity?.stringValue ?? participant.sid?.stringValue ?? "unknown"
            let name = participant.name ?? identity

            // Audio: microphone publication (prefer by source)
            let micPub = participant.audioTracks.first(where: { $0.source == .microphone })
                ?? participant.audioTracks.first(where: { $0.track != nil })
            let isAudioMuted = (micPub?.isMuted ?? true) || micPub?.track == nil
            let micEnabled = !isAudioMuted

            // Camera tile
            let camPub = participant.videoTracks.first(where: { $0.source == .camera })
                ?? participant.videoTracks.first(where: { $0.track != nil && $0.source == .unknown })
            let camTrack = camPub?.track as? VideoTrack
            let isCamMuted = (camPub?.isMuted ?? true) || camTrack == nil
            let camEnabled = !isCamMuted

            tiles.append(
                ParticipantTile(
                    id: "remote:\(participant.sid):camera",
                    identity: identity,
                    displayName: name,
                    isLocal: false,
                    videoTrack: camTrack,
                    isSpeaking: participant.isSpeaking,
                    isMicEnabled: micEnabled,
                    isCameraEnabled: camEnabled
                )
            )

            // Screen share tile (if any)
            let screenPub = participant.videoTracks.first(where: { $0.source == .screenShareVideo && $0.track != nil })
            let screenTrack = screenPub?.track as? VideoTrack
            if let screenTrack {
                tiles.append(
                    ParticipantTile(
                        id: "remote:\(participant.sid):screenshare",
                        identity: identity,
                        displayName: "\(name) — Screen",
                        isLocal: false,
                        videoTrack: screenTrack,
                        isSpeaking: false,
                        isMicEnabled: false,
                        isCameraEnabled: true
                    )
                )
            }
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
            chatMessages.append(ChatMessage(id: UUID(), kind: .user, sender: sender, text: trimmed, timestamp: Date(), isLocal: true))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func addSystemMessage(_ text: String) {
        chatMessages.append(ChatMessage(id: UUID(), kind: .system, sender: "System", text: text, timestamp: Date(), isLocal: false))
    }

    // MARK: - RoomDelegate

    nonisolated func room(_ room: Room, didUpdateConnectionState connectionState: ConnectionState, from oldConnectionState: ConnectionState) {
        Task { @MainActor in rebuildParticipantTiles() }
    }

    nonisolated func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        Task { @MainActor in
            let name = participant.name ?? participant.identity?.stringValue ?? "Participant"
            addSystemMessage("\(name) joined")
            rebuildParticipantTiles()
        }
    }

    nonisolated func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        Task { @MainActor in
            let name = participant.name ?? participant.identity?.stringValue ?? "Participant"
            addSystemMessage("\(name) left")
            rebuildParticipantTiles()
        }
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
                chatMessages.append(ChatMessage(id: UUID(), kind: .user, sender: wire.sender, text: wire.text, timestamp: Date(timeIntervalSince1970: wire.ts), isLocal: false))
                return
            }

            let sender = participant?.name ?? participant?.identity?.stringValue ?? "Participant"
            let text = String(data: data, encoding: .utf8) ?? "<binary data>"
            chatMessages.append(ChatMessage(id: UUID(), kind: .user, sender: sender, text: text, timestamp: Date(), isLocal: false))
        }
    }
}
