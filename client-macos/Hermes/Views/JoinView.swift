import SwiftUI

struct JoinView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var meetingStore: MeetingStore

    @State private var displayName: String = ""
    @State private var room: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: FocusField?

    // Local backend (use IPv4 loopback to avoid macOS preferring ::1 when server isn't bound on IPv6)
    private let backend = BackendClient(baseUrl: URL(string: "http://127.0.0.1:3001/")!)

    enum FocusField: Hashable {
        case displayName
        case room
        case joinButton
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hermes")
                .font(.largeTitle)
                .bold()

            Text("Join a room as a guest")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Display name")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Ada", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .displayName)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .room
                    }

                Text("Room code")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                TextField("demo-room", text: $room)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .room)
                    .submitLabel(.go)
                    .onSubmit {
                        Task { await join() }
                    }
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            HStack {
                Button {
                    Task { await join() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Join")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .focused($focusedField, equals: .joinButton)
                .focusable(true)
                .disabled(isLoading || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || room.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 320)
        .onAppear {
            if focusedField == nil {
                focusedField = .displayName
            }
        }
    }

    @MainActor
    private func join() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await backend.guestAuth(
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                room: room.trimmingCharacters(in: .whitespacesAndNewlines),
                desiredRole: nil
            )
            sessionStore.setSession(session)

            let join = try await backend.roomsJoin(hermesJwt: session.token, room: nil)
            meetingStore.setRoomJoin(join)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    JoinView()
        .environmentObject(SessionStore())
        .environmentObject(MeetingStore())
}
