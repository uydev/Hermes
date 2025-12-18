//
//  ContentView.swift
//  Hermes
//
//  Created by yilmazu on 18/12/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        NavigationStack {
            if sessionStore.session?.token.isEmpty == false {
                MeetingStubView()
            } else {
                JoinView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionStore())
}
