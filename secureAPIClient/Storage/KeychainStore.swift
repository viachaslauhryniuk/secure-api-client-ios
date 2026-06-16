import Security
import Foundation

enum KeychainStore {
    static let service = "APIClient"
    
    private static func baseQuery(account: String) -> [String: Any]{
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
    
    static func save(token: String, account: String) {
        let data = Data(token.utf8)
        
        var attr = baseQuery(account: account)
        SecItemDelete(attr as CFDictionary)
        
        attr[kSecValueData as String] = data
        SecItemAdd(attr as CFDictionary, nil)
    }
    
    static func delete(account: String) {
        SecItemDelete(baseQuery(account: account) as CFDictionary)
    }
    
    static func read(account: String) -> String? {
        var attr = baseQuery(account: account)
        
        attr[kSecMatchLimit as String] = kSecMatchLimitOne
        attr[kSecReturnData as String] = kCFBooleanTrue
        
        var result: AnyObject?
        let status = SecItemCopyMatching(attr as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

