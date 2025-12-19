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
    
    /// Convenience initializer that reads backend URL from build configuration or uses default
    convenience init() {
        // Read from Info.plist build setting, or use default
        let urlString: String
        
        if let configUrl = Bundle.main.object(forInfoDictionaryKey: "BackendURL") as? String,
           !configUrl.isEmpty {
            urlString = configUrl
        } else {
            // Default: localhost for development
            urlString = "http://127.0.0.1:3001"
        }
        
        // Ensure URL ends with / for proper path appending
        let normalizedUrl = urlString.hasSuffix("/") ? urlString : "\(urlString)/"
        
        guard let url = URL(string: normalizedUrl) else {
            fatalError("Invalid BackendURL in Info.plist: \(normalizedUrl)")
        }
        
        self.init(baseUrl: url)
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
