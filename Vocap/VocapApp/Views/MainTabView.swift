import SwiftUI

/// Main tab view after authentication
struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Word Bank Tab
            WordBankView()
                .tabItem {
                    Label("Word Bank", systemImage: "books.vertical.fill")
                }
                .tag(0)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(1)
        }
        .tint(.accentColor)
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
