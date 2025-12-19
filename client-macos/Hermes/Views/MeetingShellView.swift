import SwiftUI

struct MeetingShellView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var meetingStore: MeetingStore
    @EnvironmentObject private var commandCenter: MeetingCommandCenter

    @StateObject private var liveKit = LiveKitMeetingViewModel()

    @State private var sidebarSelection: SidebarTab = .participants
    @State private var isSidebarVisible: Bool = true
    @State private var chatDraft: String = ""
    @State private var isScreenSharePickerPresented: Bool = false
    @State private var isDeviceSettingsPresented: Bool = false
    @State private var stagedTileId: String? = nil
    @State private var isRecovering: Bool = false
    @State private var recoveryError: String?
    @FocusState private var focusedField: FocusField?
    @State private var layoutMode: LayoutMode = .stage

    // Backend client uses configurable URL from build settings or defaults to localhost
    private let backend = BackendClient()

    enum FocusField: Hashable {
        case chatInput
    }

    enum SidebarTab: String, CaseIterable {
        case participants = "Participants"
        case chat = "Chat"
    }

    enum LayoutMode: String, CaseIterable {
        case stage = "Stage"
        case gallery = "Gallery"
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
        .onAppear {
            commandCenter.actions = meetingActions
        }
        .onChange(of: liveKit.isScreenSharing) { _, _ in
            // Keep actions closures up-to-date with current state.
            commandCenter.actions = meetingActions
        }
        .onChange(of: isSidebarVisible) { _, _ in
            commandCenter.actions = meetingActions
        }
        .onChange(of: sidebarSelection) { _, _ in
            commandCenter.actions = meetingActions
        }
        .onDisappear {
            if commandCenter.actions != nil {
                commandCenter.actions = nil
            }
        }
        .task(id: meetingStore.roomJoin?.liveKitToken) {
            guard let join = meetingStore.roomJoin else { return }
            await liveKit.connectIfNeeded(join: join)
        }
    }

    private var meetingActions: MeetingCommandActions {
        MeetingCommandActions(
            toggleMic: { Task { await liveKit.toggleMic() } },
            toggleCamera: { Task { await liveKit.toggleCamera() } },
            toggleScreenShare: {
                if liveKit.isScreenSharing {
                    Task { await liveKit.stopScreenShare() }
                } else {
                    isScreenSharePickerPresented = true
                }
            },
            toggleSidebar: {
                withAnimation(.snappy(duration: 0.18)) {
                    isSidebarVisible.toggle()
                }
            },
            showDeviceSettings: {
                isDeviceSettingsPresented = true
            },
            focusChat: {
                withAnimation(.snappy(duration: 0.18)) {
                    isSidebarVisible = true
                }
                sidebarSelection = .chat
                focusedField = .chatInput
            },
            showParticipants: {
                withAnimation(.snappy(duration: 0.18)) {
                    isSidebarVisible = true
                }
                sidebarSelection = .participants
            },
            leaveMeeting: {
                Task { await liveKit.disconnect() }
                meetingStore.clear()
                sessionStore.signOut()
                commandCenter.actions = nil
            }
        )
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(meetingStore.roomJoin?.room ?? "")
                    .font(.headline)

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation(.snappy(duration: 0.18)) {
                    layoutMode = (layoutMode == .stage) ? .gallery : .stage
                }
            } label: {
                Label("Layout", systemImage: layoutMode == .stage ? "square.grid.2x2" : "rectangle.on.rectangle")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)

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

    private var statusText: String {
        switch liveKit.state {
        case .idle:
            return "Idle"
        case .connecting:
            return "Connecting…"
        case .connected:
            return "Connected"
        case .reconnecting:
            return "Reconnecting…"
        case .disconnected:
            return "Disconnected"
        case .failed:
            return "Error"
        }
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
                    case .connected, .reconnecting:
                        ZStack(alignment: .top) {
                            participantsGrid

                            if case .reconnecting = liveKit.state {
                                reconnectBanner(text: "Reconnecting…")
                                    .padding(.top, 10)
                            }
                        }
                    case .disconnected(let message):
                        VStack(spacing: 10) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 28))
                                .foregroundStyle(.yellow)
                            Text("Disconnected")
                                .font(.headline)
                            Text(message ?? "Connection lost.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 10) {
                                Button {
                                    Task { await recover() }
                                } label: {
                                    if isRecovering {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Text("Reconnect")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isRecovering)

                                Button("Leave") {
                                    Task { await liveKit.disconnect() }
                                    meetingStore.clear()
                                    sessionStore.signOut()
                                }
                                .buttonStyle(.bordered)
                            }

                            if let recoveryError {
                                Text(recoveryError)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 6)
                            }
                        }
                        .padding(24)
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

                            Button {
                                Task { await recover() }
                            } label: {
                                if isRecovering {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Text("Try again")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isRecovering)

                            if let recoveryError {
                                Text(recoveryError)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 6)
                            }
                        }
                        .padding(24)
                    }
                }
                .padding(20)

            // Debug info commented out - not needed in UI
            // if let join = meetingStore.roomJoin {
            //     VStack(alignment: .leading, spacing: 6) {
            //         Text("LiveKit URL: \(join.liveKitUrl)")
            //         Text("Identity: \(join.identity)")
            //         Text("Name: \(join.displayName)")
            //         Text("Role: \(join.role)")
            //     }
            //     .font(.system(.caption, design: .monospaced))
            //     .foregroundStyle(.secondary)
            //     .padding(.horizontal, 20)
            //     .padding(.bottom, 8)
            // }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func reconnectBanner(text: String) -> some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text(text)
                .font(.caption)
            Spacer()
            Button("Reconnect") {
                Task { await recover() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(isRecovering)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 14)
    }

    @MainActor
    private func recover() async {
        guard !isRecovering else { return }
        recoveryError = nil
        isRecovering = true
        defer { isRecovering = false }

        guard let hermesJwt = sessionStore.session?.token else {
            recoveryError = "Missing guest session. Please re-join."
            return
        }

        do {
            // Always mint a fresh LiveKit token and let the existing `.task(id:)` reconnect.
            let room = meetingStore.roomJoin?.room
            let join = try await backend.roomsJoin(hermesJwt: hermesJwt, room: room)
            meetingStore.setRoomJoin(join)

            // If we were connected but in a weird state, ensure local media is aligned.
            await liveKit.applyMediaState()
        } catch {
            recoveryError = error.localizedDescription
        }
    }

    private var participantsGrid: some View {
        Group {
            if layoutMode == .gallery {
                galleryGrid
            } else {
                stageLayout(stage: stageTileAny ?? (liveKit.participantTiles.first ?? placeholderTile))
            }
        }
        .onChange(of: liveKit.participantTiles.map { $0.id }) { _, ids in
            if let staged = stagedTileId, !ids.contains(staged) {
                stagedTileId = nil
            }
        }
    }

    private var placeholderTile: ParticipantTile {
        ParticipantTile(
            id: "placeholder",
            identity: "placeholder",
            displayName: "Connecting…",
            isLocal: true,
            kind: .camera,
            videoTrack: nil,
            isSpeaking: false,
            isMicEnabled: false,
            isCameraEnabled: false
        )
    }

    private var galleryGrid: some View {
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

    private var screenShareTiles: [ParticipantTile] {
        liveKit.participantTiles.filter { $0.kind == .screenShare }
    }

    private var stageTileAny: ParticipantTile? {
        let tiles = liveKit.participantTiles
        if tiles.isEmpty { return nil }

        // 1) If user pinned a tile, use it.
        if let stagedTileId, let pinned = tiles.first(where: { $0.id == stagedTileId }) {
            return pinned
        }

        // 2) Screen share always wins if present.
        if let share = tiles.first(where: { $0.kind == .screenShare }) {
            return share
        }

        // 3) Active speaker (camera tiles), prefer remote.
        if let speaker = tiles.first(where: { $0.kind == .camera && $0.isSpeaking && !$0.isLocal }) {
            return speaker
        }
        if let speaker = tiles.first(where: { $0.kind == .camera && $0.isSpeaking }) {
            return speaker
        }

        // 4) Otherwise local camera, else first.
        if let local = tiles.first(where: { $0.isLocal && $0.kind == .camera }) {
            return local
        }
        return tiles.first
    }

    private func stageLayout(stage: ParticipantTile) -> some View {
        let thumbnails = liveKit.participantTiles.filter { $0.id != stage.id }

        return VStack(spacing: 12) {
            ParticipantTileView(tile: stage)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    // Double-tap stage to unpin.
                    stagedTileId = nil
                }

            if !thumbnails.isEmpty {
                Divider()
                    .padding(.horizontal, 14)

                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(thumbnails, id: \.id) { tile in
                            ParticipantTileView(tile: tile)
                                .frame(width: 220)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    stagedTileId = tile.id
                                }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
                .scrollIndicators(.visible)
            }
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

            controlButton(title: liveKit.isScreenSharing ? "Stop Share" : "Share",
                          systemImage: liveKit.isScreenSharing ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle",
                          isActive: liveKit.isScreenSharing) {
                if liveKit.isScreenSharing {
                    Task { await liveKit.stopScreenShare() }
                } else {
                    isScreenSharePickerPresented = true
                }
            }

            Button {
                isDeviceSettingsPresented = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)

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
        .sheet(isPresented: $isScreenSharePickerPresented) {
            ScreenSharePickerView { result in
                isScreenSharePickerPresented = false
                switch result {
                case .cancelled:
                    break
                case .selected(let source):
                    Task { await liveKit.startScreenShare(source: source) }
                }
            }
        }
        .sheet(isPresented: $isDeviceSettingsPresented) {
            DeviceSettingsView(liveKit: liveKit)
        }
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

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(liveKit.chatMessages, id: \.id) { (msg: ChatMessage) in
                            if msg.kind == .system {
                                Text(msg.text)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(msg.isLocal ? "You" : msg.sender)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(msg.text)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
                .onChange(of: liveKit.chatMessages.count) { _, _ in
                    if let last = liveKit.chatMessages.last {
                        withAnimation(.snappy(duration: 0.18)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Message", text: $chatDraft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .focused($focusedField, equals: .chatInput)
                    .onSubmit {
                        let text = chatDraft
                        chatDraft = ""
                        Task { await liveKit.sendChat(text: text) }
                    }

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
