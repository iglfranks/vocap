import SwiftUI

/// Confirmation screen after magic link is sent
struct MagicLinkSentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var animateCheckmark = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated Checkmark
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)

                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 3)
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateCheckmark ? 1.2 : 1.0)
                    .opacity(animateCheckmark ? 0 : 1)
                    .animation(
                        .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: animateCheckmark
                    )

                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.green, Color.accent)
            }
            .onAppear {
                animateCheckmark = true
            }

            // Title
            VStack(spacing: 12) {
                Text("Check your inbox!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("We sent a magic link to")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text(authViewModel.email)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.accent)
            }

            // Instructions
            VStack(spacing: 16) {
                InstructionRow(number: 1, text: "Open the email we just sent")
                InstructionRow(number: 2, text: "Tap the magic link")
                InstructionRow(number: 3, text: "You'll be signed in automatically")
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal, 32)

            Spacer()

            // Footer
            VStack(spacing: 16) {
                Text("Didn't receive the email?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 24) {
                    Button("Resend") {
                        Task {
                            await authViewModel.sendMagicLink()
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.accent)
                    .disabled(authViewModel.isLoading)

                    Button("Try different email") {
                        authViewModel.backToLogin()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.accent))

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    MagicLinkSentView()
        .environmentObject(
            {
                let vm = AuthViewModel()
                vm.email = "test@example.com"
                return vm
            }())
}
