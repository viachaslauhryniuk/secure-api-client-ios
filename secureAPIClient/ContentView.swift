import SwiftUI

struct ContentView: View {
    @State private var session = SessionViewModel()

    var body: some View {
        Group {
            switch session.state {
            case .loggedOut:
                LoginView { username, password in
                    await session.login(username: username, password: password)
                }
            case .loggedIn(let username):
                VStack {
                    if session.isDeviceJailbroken {
                        jailbreakBanner
                    }
                    ProfileView(
                        username: username,
                        secureActionStatus: session.secureActionStatus,
                        onSecureAction: { Task { await session.performSecureAction() } },
                        onLogout: { session.logout() }
                    )
                }
            case .restoring:
                ProgressView()
            }
        }
        .task {
            await session.restoreSession()
        }
    }
    
    private var jailbreakBanner: some View {
        Text("this device appears to be compromised")
            .font(.footnote).bold()
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(.red)
            .foregroundStyle(.white)
    }

}
