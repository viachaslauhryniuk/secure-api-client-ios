import CryptoKit
import Foundation

enum DeviceSigningKey {
    case enclave(SecureEnclave.P256.Signing.PrivateKey)
    case software(P256.Signing.PrivateKey)

    static func make() throws -> DeviceSigningKey {
        if SecureEnclave.isAvailable {
            return .enclave(try SecureEnclave.P256.Signing.PrivateKey())  
        } else {
            return .software(P256.Signing.PrivateKey())
        }
    }

    var publicKeyPEM: String {
        switch self {
        case .enclave(let key):  return key.publicKey.pemRepresentation
        case .software(let key): return key.publicKey.pemRepresentation
        }
    }

    func signature(for data: Data) throws -> Data {
        switch self {
        case .enclave(let key):  return try key.signature(for: data).derRepresentation
        case .software(let key): return try key.signature(for: data).derRepresentation
        }
    }

    var persistableData: Data {
        switch self {
        case .enclave(let key):  return key.dataRepresentation
        case .software(let key): return key.rawRepresentation
        }
    }

    static func load(from data: Data) throws -> DeviceSigningKey {
        if SecureEnclave.isAvailable {
            return .enclave(try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: data))
        } else {
            return .software(try P256.Signing.PrivateKey(rawRepresentation: data))
        }
    }
}
