import SwiftUI

/// Root view that switches between authentication and main app
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            switch authViewModel.authState {
            case .login:
                LoginView()
                    .transition(.opacity.combined(with: .move(edge: .leading)))

            case .magicLinkSent:
                MagicLinkSentView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))

            case .authenticated:
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.authState)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
