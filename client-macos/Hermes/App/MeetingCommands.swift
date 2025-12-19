import SwiftUI

struct MeetingCommands: Commands {
    @FocusedValue(\.meetingCommandActions) private var meeting

    var body: some Commands {
        CommandMenu("Meeting") {
            Button("Mute / Unmute") {
                meeting?.toggleMic()
            }
            .keyboardShortcut("m", modifiers: [])
            .disabled(meeting == nil)

            Button("Start / Stop Video") {
                meeting?.toggleCamera()
            }
            .keyboardShortcut("v", modifiers: [])
            .disabled(meeting == nil)

            Divider()

            Button("Share Screen…") {
                meeting?.toggleScreenShare()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(meeting == nil)

            Button("Audio & Video Settings…") {
                meeting?.showDeviceSettings()
            }
            .keyboardShortcut(",", modifiers: [.command])
            .disabled(meeting == nil)

            Divider()

            Button("Focus Chat") {
                meeting?.focusChat()
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .disabled(meeting == nil)

            Button("Show Participants") {
                meeting?.showParticipants()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(meeting == nil)

            Button("Toggle Sidebar") {
                meeting?.toggleSidebar()
            }
            .keyboardShortcut("\\", modifiers: [.command])
            .disabled(meeting == nil)

            Divider()

            Button("Leave Meeting…") {
                meeting?.leaveMeeting()
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])
            .disabled(meeting == nil)
        }
    }
}
