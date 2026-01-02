import SwiftUI

/// Login screen with magic link email input
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(minHeight: geometry.size.height * 0.15)

                    // Logo and Title
                    VStack(spacing: 16) {
                        // App Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.accent, Color.accent.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: .accent.opacity(0.4), radius: 20, y: 10)

                            Text("V")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }

                        VStack(spacing: 8) {
                            Text("Vocap")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text("Build your vocabulary, one word at a time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.bottom, 48)

                    // Email Input Card
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)

                                TextField("you@example.com", text: $authViewModel.email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .focused($isEmailFocused)

                                if !authViewModel.email.isEmpty {
                                    Button {
                                        authViewModel.email = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isEmailFocused ? Color.accent : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }

                        // Error Message
                        if let error = authViewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Sign In Button
                        Button {
                            Task {
                                await authViewModel.sendMagicLink()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Continue with Email")
                                        .fontWeight(.semibold)
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(authViewModel.canSubmit ? Color.accent : Color.gray)
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(!authViewModel.canSubmit)

                        // Info Text
                        Text("We'll send you a magic link to sign in.\nNo password needed!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 20, y: 10)
                    )
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(minHeight: geometry.size.height * 0.15)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.accent.opacity(0.05),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onTapGesture {
            isEmailFocused = false
        }
    }
}

// MARK: - Accent Color Extension

extension Color {
    static let accent = Color(red: 0.4, green: 0.3, blue: 0.9)  // Purple-ish accent
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
