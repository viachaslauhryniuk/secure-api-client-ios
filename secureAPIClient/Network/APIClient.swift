import Foundation

enum APIError: Error {
    case invalidResponse
}
final class APIClient{
    static let baseURL = URL(string: "https://127.0.0.1:8000")!
    
    func login(username: String, password: String) async throws -> TokenResponse {
        let url = APIClient.baseURL.appending(path: "login")
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(LoginRequest(username: username, password: password))
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decodedToken = try decoder.decode(TokenResponse.self, from: data)
        return decodedToken
    }
    
}
