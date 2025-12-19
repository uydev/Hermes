import AppKit
import SwiftUI

/// Allows configuring the hosting NSWindow from SwiftUI.
struct WindowConfigurator: NSViewRepresentable {
    typealias NSViewType = NSView

    let minSize: CGSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            apply(to: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            apply(to: nsView)
        }
    }

    private func apply(to view: NSView) {
        guard let window = view.window else { return }

        // Sizing
        window.minSize = minSize

        // Titlebar polish
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true

        if #available(macOS 11.0, *) {
            window.toolbarStyle = .unifiedCompact
        }

        // Prevent the first toolbar autosave from fighting our min sizes.
        window.setFrameAutosaveName("HermesMainWindow")
    }
}
