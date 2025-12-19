import SwiftUI

struct MeetingCommands: Commands {
    @ObservedObject var commandCenter: MeetingCommandCenter

    var body: some Commands {
        CommandMenu("Meeting") {
            Button("Mute / Unmute") {
                commandCenter.actions?.toggleMic()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
            .disabled(commandCenter.actions == nil)

            Button("Start / Stop Video") {
                commandCenter.actions?.toggleCamera()
            }
            .keyboardShortcut("v", modifiers: [.command, .shift])
            .disabled(commandCenter.actions == nil)

            Divider()

            Button("Share Screen…") {
                commandCenter.actions?.toggleScreenShare()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(commandCenter.actions == nil)

            Button("Audio & Video Settings…") {
                commandCenter.actions?.showDeviceSettings()
            }
            .keyboardShortcut(",", modifiers: [.command])
            .disabled(commandCenter.actions == nil)

            Divider()

            Button("Focus Chat") {
                commandCenter.actions?.focusChat()
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .disabled(commandCenter.actions == nil)

            Button("Show Participants") {
                commandCenter.actions?.showParticipants()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(commandCenter.actions == nil)

            Button("Toggle Sidebar") {
                commandCenter.actions?.toggleSidebar()
            }
            .keyboardShortcut("\\", modifiers: [.command])
            .disabled(commandCenter.actions == nil)

            Divider()

            Button("Leave Meeting…") {
                commandCenter.actions?.leaveMeeting()
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])
            .disabled(commandCenter.actions == nil)
        }
    }
}
