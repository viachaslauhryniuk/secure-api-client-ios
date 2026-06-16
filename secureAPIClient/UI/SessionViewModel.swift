import SwiftUI

@MainActor
@Observable
final class SessionViewModel {
    let apiClient = APIClient()
    
    enum State {
        case loggedOut
        case loggedIn(username: String)
    }

    private(set) var state: State = .loggedOut

    func login(username: String, password: String) async -> String? {
        do {
            let token = try await apiClient.login(username: username, password: password)
            KeychainStore.save(token: token.accessToken, account: "accessToken")
            state = .loggedIn(username: username)
            return nil
        } catch {
            return "Login Failed"
        }
    }
    
    func logout() {
        KeychainStore.delete(account: "accessToken")
        state = .loggedOut
    }
}
