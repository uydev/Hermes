import SwiftUI
import LiveKit

struct DeviceSettingsView: View {
    @ObservedObject var liveKit: LiveKitMeetingViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .frame(width: 520, height: 560)
        .task {
            await liveKit.refreshDevices()
        }
    }

    private var header: some View {
        HStack {
            Text("Audio & Video")
                .font(.headline)

            Spacer()

            Button("Done") {
                dismiss()
            }
        }
        .padding(12)
    }

    private var content: some View {
        Form {
            Section("Camera") {
                Picker("Device", selection: Binding(
                    get: { liveKit.selectedCameraId ?? "" },
                    set: { id in Task { await liveKit.selectCamera(deviceId: id) } }
                )) {
                    ForEach(liveKit.cameraDevices) { cam in
                        Text(cam.name).tag(cam.id)
                    }
                }
                .pickerStyle(.menu)

                Text("Tip: if the camera is in use by another app, close it and retry.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Microphone") {
                Picker("Input", selection: Binding(
                    get: { liveKit.selectedMicId ?? "" },
                    set: { id in Task { await liveKit.selectMicrophone(deviceId: id) } }
                )) {
                    ForEach(liveKit.micDevices) { dev in
                        Text(dev.name).tag(dev.deviceId)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Speaker") {
                Picker("Output", selection: Binding(
                    get: { liveKit.selectedSpeakerId ?? "" },
                    set: { id in Task { await liveKit.selectSpeaker(deviceId: id) } }
                )) {
                    ForEach(liveKit.speakerDevices) { dev in
                        Text(dev.name).tag(dev.deviceId)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .formStyle(.grouped)
        .padding(12)
    }
}

#Preview {
    DeviceSettingsView(liveKit: LiveKitMeetingViewModel())
}
