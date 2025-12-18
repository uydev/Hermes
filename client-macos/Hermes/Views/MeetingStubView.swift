import SwiftUI

struct MeetingStubView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connected (Phase 1)")
                .font(.title2)
                .bold()

            if let session = sessionStore.session {
                Text("Room: \(session.room)")
                Text("Name: \(session.displayName)")
                Text("Role: \(session.role)")
                Text("Identity: \(session.identity)")

                Divider()

                Text("Hermes JWT (stored in Keychain)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(session.token)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(6)
            }

            HStack {
                Button("Sign out") {
                    sessionStore.signOut()
                }

                Spacer()
            }

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 320)
    }
}

#Preview {
    let store = SessionStore()
    store.setSession(GuestSession(token: "token", expiresAt: 0, expiresInSeconds: 0, identity: "id", displayName: "Ada", room: "demo-room", role: "participant"))
    return MeetingStubView().environmentObject(store)
}
