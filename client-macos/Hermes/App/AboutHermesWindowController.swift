import AppKit
import SwiftUI

@MainActor
final class AboutHermesWindowController: NSWindowController, NSWindowDelegate {
    static let shared = AboutHermesWindowController()

    private init() {
        let hosting = NSHostingController(rootView: AboutHermesView())

        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.title = "About Hermes"
        window.isReleasedWhenClosed = false
        window.center()
        window.backgroundColor = .windowBackgroundColor
        window.isOpaque = true

        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        // Keep the controller alive for reuse.
    }
}
