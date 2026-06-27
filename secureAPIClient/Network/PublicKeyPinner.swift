import Foundation
import CryptoKit

final class PublicKeyPinner: NSObject, URLSessionDelegate {

    private let pinnedKeyHash = "DNC3pyk7XJczGOAQtCPJK087sf39BfqcrTpCTGRQoQ4="

    private let rsa2048Header: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86,
        0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03,
        0x82, 0x01, 0x0f, 0x00
    ]

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let pin = pinHash(for: serverTrust),
              pin == pinnedKeyHash
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }

    private func pinHash(for trust: SecTrust) -> String? {
        guard let publicKey = SecTrustCopyKey(trust),
              let rawKey = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?
        else {
            return nil
        }

        var spki = Data(rsa2048Header)
        spki.append(rawKey)
        let hash = SHA256.hash(data: spki)
        return Data(hash).base64EncodedString()
    }
}
