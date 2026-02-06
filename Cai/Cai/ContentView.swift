import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clipboard")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("Cai is running")
                .font(.title)
                .fontWeight(.semibold)

            Text("Press ⌥C (Option+C) to capture clipboard")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Your clipboard manager is active")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
