//
//  HermesApp.swift
//  Hermes
//
//  Created by yilmazu on 18/12/2025.
//

import SwiftUI
import AppKit

@main
struct HermesApp: App {
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var meetingStore = MeetingStore()
    @StateObject private var commandCenter = MeetingCommandCenter()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionStore)
                .environmentObject(meetingStore)
                .environmentObject(commandCenter)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Hermes") {
                    showAboutHermes()
                }
            }
            MeetingCommands(commandCenter: commandCenter)
        }
    }

    private func showAboutHermes() {
        AboutHermesWindowController.shared.show()
    }
}
