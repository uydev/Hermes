import SwiftUI
import AppKit

struct JoinView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var meetingStore: MeetingStore

    @State private var displayName: String = ""
    @State private var room: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: FocusField?

    // Backend client uses configurable URL from build settings or defaults to localhost
    private let backend = BackendClient()

    enum FocusField: Hashable {
        case displayName
        case room
        case joinButton
    }

    var body: some View {
        ZStack {
            // Force a real background + primary foreground so text can't disappear due to
            // accidental global styles, transparency, or vibrancy issues.
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                    .padding(.bottom, 6)

                VStack(spacing: 6) {
                    Text("Hermes")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("Join a room as a guest")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Display name")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("Ada", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .displayName)
                            .submitLabel(.next)
                            .disabled(isLoading)
                            .onSubmit { focusedField = .room }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Room code")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("demo-room", text: $room)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .room)
                            .submitLabel(.go)
                            .disabled(isLoading)
                            .onSubmit { Task { await join() } }
                    }
                }
                .controlSize(.large)
                .frame(maxWidth: 420)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: 420, alignment: .leading)
                }

                HStack {
                    Spacer()

                    Button {
                        Task { await join() }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(isLoading ? "Joining…" : "Join")
                                .fontWeight(.semibold)
                        }
                        .frame(minWidth: 96)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .focused($focusedField, equals: .joinButton)
                    .focusable(true)
                    .disabled(isLoading || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || room.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .frame(maxWidth: 420)

                Spacer(minLength: 0)
            }
            .foregroundStyle(.primary)
            .padding(24)
            .frame(minWidth: 520, minHeight: 360, alignment: .top)
            .onAppear {
                if focusedField == nil {
                    focusedField = .displayName
                }
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
