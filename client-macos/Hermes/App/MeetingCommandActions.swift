import SwiftUI

struct MeetingCommandActions {
    let toggleMic: () -> Void
    let toggleCamera: () -> Void
    let toggleScreenShare: () -> Void
    let toggleSidebar: () -> Void
    let showDeviceSettings: () -> Void
    let focusChat: () -> Void
    let showParticipants: () -> Void
    let leaveMeeting: () -> Void
}
