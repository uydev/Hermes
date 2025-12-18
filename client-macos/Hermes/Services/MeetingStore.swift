import Foundation
import Combine

@MainActor
final class MeetingStore: ObservableObject {
    @Published private(set) var roomJoin: RoomJoinResponse?

    func setRoomJoin(_ join: RoomJoinResponse) {
        self.roomJoin = join
    }

    func clear() {
        self.roomJoin = nil
    }
}
