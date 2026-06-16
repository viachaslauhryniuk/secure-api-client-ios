import SwiftUI

struct ContentView: View {
    @State private var session = SessionViewModel()

    var body: some View {
        switch session.state {
        case .loggedOut:
            LoginView { username, password in
                await session.login(username: username, password: password)
            }
        case .loggedIn(let username):
            ProfileView(username: username) {
                session.logout()
            }
        }
    }
}
