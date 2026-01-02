import SwiftData
import SwiftUI

/// Main entry point for the Vocap app
@main
struct VocapApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    // Handle magic link callback
                    Task {
                        await authViewModel.handleMagicLinkCallback(url: url)
                    }
                }
        }
    }
}
