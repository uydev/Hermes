import SwiftUI
import LiveKit
import CoreGraphics
import AppKit

/// Lets the user pick a display or window to share (macOS 12.3+).
struct ScreenSharePickerView: View {
    enum Result {
        case selected(MacOSScreenCaptureSource)
        case cancelled
    }

    let onResult: (Result) -> Void

    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var displays: [MacOSDisplay] = []
    @State private var windows: [MacOSWindow] = []

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            content
        }
        .frame(width: 520, height: 520)
        .task {
            await loadSources()
        }
    }

    private var header: some View {
        HStack {
            Text("Share screen")
                .font(.headline)

            Spacer()

            Button("Cancel") {
                onResult(.cancelled)
            }
        }
        .padding(12)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 10) {
                ProgressView()
                Text("Loading shareable content…")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text("Unable to list screens/windows")
                    .font(.headline)
                Text(errorMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)

                HStack(spacing: 10) {
                    Button("Retry") {
                        Task { await loadSources() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Open Screen Recording Settings") {
                        openScreenRecordingSettings()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 6)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                if !displays.isEmpty {
                    Section("Displays") {
                        ForEach(displays, id: \.displayID) { display in
                            Button {
                                onResult(.selected(display))
                            } label: {
                                HStack {
                                    Image(systemName: "display")
                                    Text("Display \(display.displayID)")
                                    Spacer()
                                    Text("\(display.width)×\(display.height)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !windows.isEmpty {
                    Section("Windows") {
                        ForEach(windows, id: \.windowID) { win in
                            Button {
                                onResult(.selected(win))
                            } label: {
                                HStack {
                                    Image(systemName: "macwindow")
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(win.title ?? "Untitled")
                                            .lineLimit(1)
                                        Text(win.owningApplication?.applicationName ?? "")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    @MainActor
    private func loadSources() async {
        isLoading = true
        errorMessage = nil

        do {
            if #available(macOS 12.3, *) {
                // ScreenCaptureKit is gated by the Screen Recording (TCC) permission.
                // If the user previously clicked "Don't Allow", the only way to recover is:
                // System Settings → Privacy & Security → Screen Recording → enable Hermes, then relaunch Hermes.
                if !CGPreflightScreenCaptureAccess() {
                    let granted = CGRequestScreenCaptureAccess()
                    if !granted {
                        errorMessage =
                            "Screen Recording permission is not granted.\n\n" +
                            "Go to System Settings → Privacy & Security → Screen Recording, enable “Hermes”, then quit and relaunch Hermes.\n\n" +
                            "If you see multiple Hermes entries, enable the one that matches the app you’re running."
                        isLoading = false
                        return
                    }

                    // Give TCC a moment to apply before querying shareable content.
                    try? await Task.sleep(nanoseconds: 350_000_000)
                }

                displays = try await MacOSScreenCapturer.displaySources()
                windows = try await MacOSScreenCapturer.windowSources()
            } else {
                errorMessage = "Screen sharing requires macOS 12.3 or later."
            }
        } catch {
            // Provide a more actionable message for the common TCC denial case.
            let msg = error.localizedDescription
            if msg.lowercased().contains("declined tcc") || msg.lowercased().contains("tcc") {
                errorMessage =
                    "\(msg)\n\n" +
                    "Go to System Settings → Privacy & Security → Screen Recording, enable “Hermes”, then quit and relaunch Hermes."
            } else {
                errorMessage = msg
            }
        }

        isLoading = false
    }

    private func openScreenRecordingSettings() {
        // Apple doesn’t guarantee deep links across macOS releases, so we try a couple.
        let candidates: [String] = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity?Privacy_ScreenCapture",
        ]
        for s in candidates {
            if let url = URL(string: s) {
                NSWorkspace.shared.open(url)
                return
            }
        }
    }
}

#Preview {
    ScreenSharePickerView { _ in }
}
