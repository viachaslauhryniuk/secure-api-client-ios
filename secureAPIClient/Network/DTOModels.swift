struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct TokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
}

struct UserResponse: Codable {
    let username: String
}

struct ChallengeResponse: Codable {
    let challenge: String
}

struct RegisterKeyRequest: Codable {
    let keyId: String
    let publicKeyPem: String
    let challenge: String
    let signature: String
}

struct AssertRequest: Codable {
    let keyId: String
    let challenge: String
    let signature: String
}
