import Foundation

struct RoomJoinResponse: Codable, Equatable {
    let liveKitUrl: String
    let liveKitToken: String
    let expiresInSeconds: Int
    let identity: String
    let displayName: String
    let room: String
    let role: String
}
