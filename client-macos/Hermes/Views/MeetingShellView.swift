import SwiftUI

struct MeetingShellView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var meetingStore: MeetingStore

    @State private var sidebarSelection: SidebarTab = .participants
    @State private var isSidebarVisible: Bool = true

    @State private var isMuted = false
    @State private var isCameraOff = false

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
            // Placeholder “stage” tile (will become active speaker / grid)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "video")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                        Text("Video stage (Phase 2 wiring)")
                            .font(.headline)
                        Text("Next: connect LiveKit + render tracks")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(24)
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

    private var bottomBar: some View {
        HStack(spacing: 10) {
            controlButton(title: isMuted ? "Unmute" : "Mute",
                          systemImage: isMuted ? "mic.slash.fill" : "mic.fill",
                          isActive: isMuted) {
                isMuted.toggle()
            }

            controlButton(title: isCameraOff ? "Start Video" : "Stop Video",
                          systemImage: isCameraOff ? "video.slash.fill" : "video.fill",
                          isActive: isCameraOff) {
                isCameraOff.toggle()
            }

            Spacer()

            Button(role: .destructive) {
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
                if let join = meetingStore.roomJoin {
                    Label("\(join.displayName) (You)", systemImage: "person.fill")
                } else {
                    Text("No session")
                }
            }
            .listStyle(.inset)
        }
    }

    private var chatPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chat")
                .font(.headline)
                .padding(.top, 12)
                .padding(.horizontal, 12)

            Spacer()

            Text("Chat comes in Phase 3")
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)

            Spacer()
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
