import Foundation
import Combine

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var session: GuestSession?

    private let keychain = KeychainStore(service: "com.hephaestus-systems.hermes")
    private let tokenAccount = "hermes.guest.jwt"

    init() {
        do {
            if let token = try keychain.getString(account: tokenAccount) {
                // For Phase 1 we only persist the raw token.
                // Session metadata will be re-fetched / re-issued during join.
                self.session = GuestSession(
                    token: token,
                    expiresAt: 0,
                    expiresInSeconds: 0,
                    identity: "",
                    displayName: "",
                    room: "",
                    role: "participant"
                )
            }
        } catch {
            self.session = nil
        }
    }

    func setSession(_ newSession: GuestSession) {
        self.session = newSession
        do {
            try keychain.setString(newSession.token, account: tokenAccount)
        } catch {
            // Best-effort; keep in-memory session.
        }
    }

    func signOut() {
        self.session = nil
        do {
            try keychain.delete(account: tokenAccount)
        } catch {
            // ignore
        }
    }
}
