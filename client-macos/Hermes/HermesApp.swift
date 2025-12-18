//
//  HermesApp.swift
//  Hermes
//
//  Created by yilmazu on 18/12/2025.
//

import SwiftUI

@main
struct HermesApp: App {
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionStore)
        }
    }
}
