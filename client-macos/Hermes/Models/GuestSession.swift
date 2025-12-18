import Foundation

struct GuestSession: Codable, Equatable {
    let token: String
    let expiresAt: Int
    let expiresInSeconds: Int
    let identity: String
    let displayName: String
    let room: String
    let role: String
}
