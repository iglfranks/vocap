import AuthenticationServices
import SwiftUI

/// Login view with Sign in with Apple authentication
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App Icon/Title
            VStack(spacing: 16) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)

                Text("Vocap")
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                Text("Build your vocabulary")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Sign in options
            VStack(spacing: 20) {
                // Sign in with Apple button
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    Task {
                        await authViewModel.handleSignInWithApple(result: result)
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Alternative: Continue with iCloud only
                Button {
                    Task {
                        await authViewModel.checkiCloudStatus()
                    }
                } label: {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        } else {
                            Image(systemName: "icloud")
                            Text("Continue with iCloud")
                        }
                    }
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(authViewModel.isLoading)

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Footer
            Text("Your vocabulary syncs automatically via iCloud")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 32)
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
