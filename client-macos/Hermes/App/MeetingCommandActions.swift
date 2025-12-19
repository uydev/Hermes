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

private struct MeetingCommandActionsKey: FocusedValueKey {
    typealias Value = MeetingCommandActions
}

extension FocusedValues {
    var meetingCommandActions: MeetingCommandActions? {
        get { self[MeetingCommandActionsKey.self] }
        set { self[MeetingCommandActionsKey.self] = newValue }
    }
}
