import SwiftUI

struct MeetingShellView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var meetingStore: MeetingStore

    @StateObject private var liveKit = LiveKitMeetingViewModel()

    @State private var sidebarSelection: SidebarTab = .participants
    @State private var isSidebarVisible: Bool = true
    @State private var chatDraft: String = ""

    enum SidebarTab: String, CaseIterable {
        case participants = "Participants"
        case chat = "Chat"
    }

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    topBar

                    Divider()

                    mainStage

                    Divider()

                    bottomBar
                }

                if isSidebarVisible {
                    Divider()
                    sidebar
                        .frame(width: 320)
                }
            }
        }
        .toolbar(.hidden)
        .task(id: meetingStore.roomJoin?.liveKitToken) {
            guard let join = meetingStore.roomJoin else { return }
            await liveKit.connectIfNeeded(join: join)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(meetingStore.roomJoin?.room ?? "")
                    .font(.headline)

                Text("Connected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation(.snappy(duration: 0.18)) {
                    isSidebarVisible.toggle()
                }
            } label: {
                Label("Sidebar", systemImage: isSidebarVisible ? "sidebar.right" : "sidebar.right")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
        .background(.ultraThinMaterial)
    }

    private var mainStage: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    switch liveKit.state {
                    case .idle, .connecting:
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("Connecting…")
                                .font(.headline)
                            Text("Preparing camera and microphone")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(24)
                    case .connected:
                        participantsGrid
                    case .failed(let message):
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.yellow)
                            Text("Failed to start video")
                                .font(.headline)
                            Text(message)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)
                    }
                }
                .padding(20)

            if let join = meetingStore.roomJoin {
                VStack(alignment: .leading, spacing: 6) {
                    Text("LiveKit URL: \(join.liveKitUrl)")
                    Text("Identity: \(join.identity)")
                    Text("Name: \(join.displayName)")
                    Text("Role: \(join.role)")
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var participantsGrid: some View {
        ScrollView {
            let cols = [GridItem(.adaptive(minimum: 280, maximum: 520), spacing: 14)]
            LazyVGrid(columns: cols, spacing: 14) {
                ForEach(liveKit.participantTiles, id: \.id) { (tile: ParticipantTile) in
                    ParticipantTileView(tile: tile)
                }
            }
            .padding(14)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            controlButton(title: liveKit.isMicEnabled ? "Mute" : "Unmute",
                          systemImage: liveKit.isMicEnabled ? "mic.fill" : "mic.slash.fill",
                          isActive: !liveKit.isMicEnabled) {
                Task { await liveKit.toggleMic() }
            }

            controlButton(title: liveKit.isCameraEnabled ? "Stop Video" : "Start Video",
                          systemImage: liveKit.isCameraEnabled ? "video.fill" : "video.slash.fill",
                          isActive: !liveKit.isCameraEnabled) {
                Task { await liveKit.toggleCamera() }
            }

            Spacer()

            Button(role: .destructive) {
                Task { await liveKit.disconnect() }
                meetingStore.clear()
                sessionStore.signOut()
            } label: {
                Text("Leave")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(12)
        .background(.ultraThinMaterial)
    }

    private func controlButton(title: String, systemImage: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .tint(isActive ? .red : .accentColor)
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            Picker("", selection: $sidebarSelection) {
                ForEach(SidebarTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(12)

            Divider()

            Group {
                switch sidebarSelection {
                case .participants:
                    participantsPanel
                case .chat:
                    chatPanel
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.thinMaterial)
    }

    private var participantsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Participants")
                .font(.headline)
                .padding(.top, 12)
                .padding(.horizontal, 12)

            List {
                ForEach(liveKit.participantTiles, id: \.id) { (tile: ParticipantTile) in
                    HStack(spacing: 10) {
                        Image(systemName: tile.isLocal ? "person.fill" : "person")
                        Text(tile.isLocal ? "\(tile.displayName) (You)" : tile.displayName)
                        Spacer()
                        Image(systemName: tile.isMicEnabled ? "mic.fill" : "mic.slash.fill")
                            .foregroundStyle(tile.isMicEnabled ? Color.secondary : Color.red)
                        Image(systemName: tile.isCameraEnabled ? "video.fill" : "video.slash.fill")
                            .foregroundStyle(tile.isCameraEnabled ? Color.secondary : Color.red)
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private var chatPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Chat")
                    .font(.headline)
                Spacer()
            }
            .padding(.top, 12)
            .padding(.horizontal, 12)

            List {
                ForEach(liveKit.chatMessages, id: \.id) { (msg: ChatMessage) in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(msg.isLocal ? "You" : msg.sender)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(msg.text)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.inset)

            Divider()

            HStack(spacing: 8) {
                TextField("Message", text: $chatDraft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button("Send") {
                    let text = chatDraft
                    chatDraft = ""
                    Task { await liveKit.sendChat(text: text) }
                }
                .disabled(chatDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding(12)
        }
    }
}

#Preview {
    let session = SessionStore()
    let meeting = MeetingStore()
    meeting.setRoomJoin(RoomJoinResponse(
        liveKitUrl: "wss://example.livekit.cloud",
        liveKitToken: "token",
        expiresInSeconds: 3600,
        identity: "user-123",
        displayName: "Ada",
        room: "demo-room",
        role: "participant"
    ))
    return MeetingShellView()
        .environmentObject(session)
        .environmentObject(meeting)
}
