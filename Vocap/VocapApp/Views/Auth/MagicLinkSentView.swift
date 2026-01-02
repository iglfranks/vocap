import SwiftUI

/// View shown after magic link is sent
struct MagicLinkSentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success Icon
            Image(systemName: "envelope.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            // Title and Message
            VStack(spacing: 12) {
                Text("Check Your Email")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("We sent a magic link to")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text(authViewModel.email)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                
                Text("Click the link in the email to sign in")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Actions
            VStack(spacing: 16) {
                Button {
                    Task {
                        await authViewModel.sendMagicLink()
                    }
                } label: {
                    Text("Resend Magic Link")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    authViewModel.backToLogin()
                } label: {
                    Text("Back to Login")
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Preview

#Preview {
    MagicLinkSentView()
        .environmentObject({
            let vm = AuthViewModel()
            vm.email = "user@example.com"
            vm.authState = .magicLinkSent
            return vm
        }())
}

