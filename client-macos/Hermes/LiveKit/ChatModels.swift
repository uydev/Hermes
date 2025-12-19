import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let sender: String
    let text: String
    let timestamp: Date
    let isLocal: Bool
}

struct ChatWireMessage: Codable {
    let type: String
    let sender: String
    let text: String
    let ts: Double
}
