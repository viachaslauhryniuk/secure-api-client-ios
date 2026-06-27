import SwiftUI

struct ProfileView: View {
    let username: String
    let secureActionStatus: String?
    var onSecureAction: () -> Void
    var onLogout: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            VStack(spacing: 4) {
                Text("Signed in as")
                    .foregroundStyle(.secondary)
                Text(username)
                    .font(.title2.bold())
            }

            Spacer()

            VStack(spacing: 8) {
                Button("Do secure action", action: onSecureAction)
                    .buttonStyle(.bordered)
                if let secureActionStatus {
                    Text(secureActionStatus)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
            }

            Button("Log Out", role: .destructive, action: onLogout)
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
        .padding(24)
    }
}
