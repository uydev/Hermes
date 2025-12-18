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
            } else {
                JoinView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionStore())
        .environmentObject(MeetingStore())
}
