import Foundation

enum BackendError: Error, LocalizedError {
    case invalidUrl
    case httpError(Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidUrl: return "Invalid backend URL"
        case .httpError(let code): return "Backend request failed (HTTP \(code))"
        case .decodingError: return "Failed to decode response"
        }
    }
}

final class BackendClient {
    private let baseUrl: URL

    init(baseUrl: URL) {
        self.baseUrl = baseUrl
    }

    struct GuestAuthRequest: Codable {
        let displayName: String
        let room: String
        let desiredRole: String?
    }

    func guestAuth(displayName: String, room: String, desiredRole: String? = nil) async throws -> GuestSession {
        let url = baseUrl.appendingPathComponent("auth/guest")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = GuestAuthRequest(displayName: displayName, room: room, desiredRole: desiredRole)
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw BackendError.decodingError }
        guard (200..<300).contains(http.statusCode) else { throw BackendError.httpError(http.statusCode) }

        do {
            return try JSONDecoder().decode(GuestSession.self, from: data)
        } catch {
            throw BackendError.decodingError
        }
    }

    struct RoomsJoinRequest: Codable {
        let room: String?
    }

    func roomsJoin(hermesJwt: String, room: String? = nil) async throws -> RoomJoinResponse {
        let url = baseUrl.appendingPathComponent("rooms/join")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(hermesJwt)", forHTTPHeaderField: "Authorization")

        let payload = RoomsJoinRequest(room: room)
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw BackendError.decodingError }
        guard (200..<300).contains(http.statusCode) else { throw BackendError.httpError(http.statusCode) }

        do {
            return try JSONDecoder().decode(RoomJoinResponse.self, from: data)
        } catch {
            throw BackendError.decodingError
        }
    }
}
