import AVFoundation
import Foundation

struct CameraDeviceOption: Identifiable, Hashable {
    let id: String
    let name: String
    let device: AVCaptureDevice

    init(device: AVCaptureDevice) {
        self.id = device.uniqueID
        self.name = device.localizedName
        self.device = device
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CameraDeviceOption, rhs: CameraDeviceOption) -> Bool {
        lhs.id == rhs.id
    }
}
