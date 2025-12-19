import Foundation
import SwiftUI
import Combine

@MainActor
final class MeetingCommandCenter: ObservableObject {
    @Published var actions: MeetingCommandActions? = nil
}
