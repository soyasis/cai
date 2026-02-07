import SwiftUI

/// About window content — shows app name, version, tagline, and GitHub link.
struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 4)

            // App icon
            Image("CaiLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            // App name
            VStack(spacing: 4) {
                Text("Cai")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.caiTextPrimary)

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.system(size: 12))
                    .foregroundColor(.caiTextSecondary)
            }

            // Tagline
            Text("Smart clipboard actions\npowered by local AI")
                .font(.system(size: 13))
                .foregroundColor(.caiTextSecondary)
                .multilineTextAlignment(.center)

            // GitHub link
            Button(action: {
                if let url = URL(string: "https://github.com/soyasis/cai") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 11))
                    Text("GitHub")
                        .font(.system(size: 12))
                }
                .foregroundColor(.caiPrimary)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }

            Spacer().frame(height: 4)
        }
        .frame(width: 260, height: 220)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("About Cai")
    }
}
