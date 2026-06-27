import Foundation

@MainActor
final class AppAttestService {
    private let api: APIClient
    private let key: DeviceSigningKey
    private let keyId: String
    private let alreadyRegistered: Bool

    init(api: APIClient) throws {
        self.api = api

        if let blobB64 = KeychainStore.read(account: "deviceKey"),
           let blob = Data(base64Encoded: blobB64),
           let savedKeyId = KeychainStore.read(account: "deviceKeyId") {
            self.key = try DeviceSigningKey.load(from: blob)
            self.keyId = savedKeyId
            self.alreadyRegistered = true
        } else {
            let newKey = try DeviceSigningKey.make()
            let newKeyId = UUID().uuidString
            KeychainStore.save(token: newKey.persistableData.base64EncodedString(), account: "deviceKey")
            KeychainStore.save(token: newKeyId, account: "deviceKeyId")
            self.key = newKey
            self.keyId = newKeyId
            self.alreadyRegistered = false
        }
    }

    func ensureRegistered() async throws {
        if alreadyRegistered { return }
        try await register()
    }

    private func register() async throws {
        let challenge = try await api.challenge()
        let signature = try key.signature(for: Data(challenge.utf8)).base64EncodedString()
        try await api.registerKey(keyId: keyId,
                                  publicKeyPem: key.publicKeyPEM,
                                  challenge: challenge,
                                  signature: signature)
    }

    func assert() async throws {
        let challenge = try await api.challenge()
        let signature = try key.signature(for: Data(challenge.utf8)).base64EncodedString()
        try await api.assert(keyId: keyId, challenge: challenge, signature: signature)
    }
}
