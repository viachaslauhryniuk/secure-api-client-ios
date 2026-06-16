import SwiftUI

struct LoginView: View {
    var onLogin: (String, String) async -> String?

    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !username.isEmpty && !password.isEmpty && !isLoading
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 52))
                    .foregroundStyle(.tint)
                Text("Secure API Client")
                    .font(.title.bold())
            }

            VStack(spacing: 12) {
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
                    .textContentType(.password)
            }
            .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: submit) {
                Group {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Sign In").bold()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canSubmit)

            Spacer()
        }
        .padding(24)
    }

    private func submit() {
        Task { @MainActor in
            errorMessage = nil
            isLoading = true
            errorMessage = await onLogin(username, password)
            isLoading = false
        }
    }
}

