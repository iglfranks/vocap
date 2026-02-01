import SwiftData
import SwiftUI

/// Main entry point for the Vocap app
@main
struct VocapApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    /// Use the shared repository's model container for SwiftData CloudKit sync
    var sharedModelContainer: ModelContainer {
        WordRepository.shared.modelContainer
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .modelContainer(sharedModelContainer)
        }
    }
}
