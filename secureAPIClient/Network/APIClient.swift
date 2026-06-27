import Foundation

enum APIError: Error {
    case invalidResponse
    case unathourized
}
final class APIClient{
    static let baseURL = URL(string: "https://127.0.0.1:8443")!
    
    private let sharedDecoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        return dec
    }()
    
    private let sharedEncoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        return enc
    }()
        
    private let session = URLSession(configuration: .default,
                                     delegate: PublicKeyPinner(),
                                     delegateQueue: nil)

    func login(username: String, password: String) async throws -> TokenResponse {
        let url = APIClient.baseURL.appending(path: "login")
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(LoginRequest(username: username, password: password))
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if httpResponse.statusCode == 401 {
            throw APIError.unathourized
        }
        guard httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decodedToken = try sharedDecoder.decode(TokenResponse.self, from: data)
        return decodedToken
    }
    
    func getProfile(token: String) async throws -> UserResponse {
        let url = APIClient.baseURL.appending(path: "profile")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if httpResponse.statusCode == 401 {
            throw APIError.unathourized
        }
        guard httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decodedUser = try sharedDecoder.decode(UserResponse.self, from: data)
        return decodedUser
    }
    
    func challenge() async throws -> String {
        let url = APIClient.baseURL.appending(path: "attest/challenge")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decodedChallenge = try sharedDecoder.decode(ChallengeResponse.self, from: data).challenge
        return decodedChallenge
    }
    
    func registerKey(keyId: String, publicKeyPem: String, challenge: String, signature: String) async throws {
        let url = APIClient.baseURL.appending(path: "attest/register")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try sharedEncoder.encode(RegisterKeyRequest(keyId: keyId, publicKeyPem: publicKeyPem, challenge: challenge, signature: signature))
        
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if http.statusCode == 401 { throw APIError.unathourized }
        guard http.statusCode == 200 else { throw APIError.invalidResponse }

    }
    
    func assert(keyId: String, challenge: String, signature: String) async throws {
        let url = APIClient.baseURL.appending(path: "attest/assert")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try sharedEncoder.encode(AssertRequest(keyId: keyId, challenge: challenge, signature: signature))
        
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if http.statusCode == 401 { throw APIError.unathourized }
        guard http.statusCode == 200 else { throw APIError.invalidResponse }
    }
}

    
