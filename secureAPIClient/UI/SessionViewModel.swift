import SwiftUI

@MainActor
@Observable
final class SessionViewModel {
    let apiClient = APIClient()
    
    enum State {
        case loggedOut
        case loggedIn(username: String)
        case restoring
    }

    private(set) var state: State = .restoring
    let isDeviceJailbroken = JailbreakDetector.isCompromisedDevice
    private(set) var secureActionStatus: String?
    
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
    
    func restoreSession() async {
        if let token = KeychainStore.read(account: "accessToken") {
            do {
                let profile = try await apiClient.getProfile(token: token)
                state = .loggedIn(username: profile.username)
            }
            
            catch APIError.unathourized {
                KeychainStore.delete(account: "accessToken")
                state = .loggedOut
            }
            
            catch {
                state = .loggedOut
            }
        }
        else {
            state = .loggedOut
        }
    }

    func performSecureAction() async {
        guard !isDeviceJailbroken else {
            secureActionStatus = "compromised device"
            return
        }
        guard let token = KeychainStore.read(account: "accessToken") else {
            secureActionStatus = "not authenticated"
            return
        }
        do {
            let attest = try AppAttestService(api: apiClient)
            try await attest.ensureRegistered()
            try await attest.assert()
            let profile = try await apiClient.getProfile(token: token)
            secureActionStatus = "secure action OK — \(profile.username)"
        } catch APIError.unathourized {
            secureActionStatus = "token or attestation rejected"
        } catch {
            secureActionStatus = "attestation or request failed"
        }
    }
}
