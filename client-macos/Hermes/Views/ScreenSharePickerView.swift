import SwiftUI
import LiveKit

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
                displays = try await MacOSScreenCapturer.displaySources()
                windows = try await MacOSScreenCapturer.windowSources()
            } else {
                errorMessage = "Screen sharing requires macOS 12.3 or later."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    ScreenSharePickerView { _ in }
}
