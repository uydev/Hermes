import SwiftUI
import AppKit

struct AboutHermesView: View {
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Hermes"
    }

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            HStack(alignment: .top, spacing: 18) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 10) {
                    Text(appName)
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    Text(versionString)
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Divider()
                        .padding(.vertical, 4)

                    Text("Developed by Hephaestus Systems (James)")
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .padding(22)
        }
        .foregroundStyle(.primary)
        .frame(width: 520, height: 240)
    }
}

#Preview {
    AboutHermesView()
}
