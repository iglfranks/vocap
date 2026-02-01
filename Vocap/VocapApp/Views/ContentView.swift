import SwiftUI

/// Root view that switches between authentication and main app
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            switch authViewModel.authState {
            case .unknown, .checking:
                // Loading state
                loadingView

            case .signedIn:
                MainTabView()
                    .transition(.opacity)

            case .signedOut:
                LoginView()
                    .transition(.opacity)

            case .iCloudUnavailable(let reason):
                iCloudUnavailableView(reason: reason)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.authState)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Checking iCloud...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func iCloudUnavailableView(reason: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "icloud.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("iCloud Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text(reason)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)

            Button {
                Task {
                    await authViewModel.checkiCloudStatus()
                }
            } label: {
                Text("Try Again")
                    .font(.subheadline)
            }
            .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
