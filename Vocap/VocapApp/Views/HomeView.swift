import SwiftUI

/// Minimal home view showing login success
struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white, Color.green)
                    .symbolEffect(.bounce, value: showConfetti)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showConfetti = true
                }
            }

            // Success Message
            VStack(spacing: 12) {
                Text("Login Success!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                if let user = authViewModel.currentUser {
                    Text("Welcome, \(user.email)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }

            // User Info Card
            if let user = authViewModel.currentUser {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accent)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Signed in as")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(user.email)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 32)
            }

            Spacer()

            // Sign Out Button
            Button {
                Task {
                    await authViewModel.signOut()
                }
            } label: {
                HStack(spacing: 8) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                    } else {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.red)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(authViewModel.isLoading)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.green.opacity(0.05),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
