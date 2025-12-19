//
//  ContentView.swift
//  Hermes
//
//  Created by yilmazu on 18/12/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var meetingStore: MeetingStore

    var body: some View {
        NavigationStack {
            if meetingStore.roomJoin != nil {
                MeetingShellView()
                    .background(WindowConfigurator(minSize: CGSize(width: 980, height: 640)))
            } else {
                JoinView()
                    .background(WindowConfigurator(minSize: CGSize(width: 520, height: 360)))
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionStore())
        .environmentObject(MeetingStore())
}
