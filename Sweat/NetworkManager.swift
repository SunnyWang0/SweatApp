import Foundation

struct AnalysisResponse: Codable {
    struct Ingredient: Codable {
        let name: String
        let quantity: String
        let effects: [String]
    }
    
    struct Qualities: Codable {
        let pump: Int
        let energy: Int
        let focus: Int
        let recovery: Int
        let endurance: Int
    }
    
    let ingredients: [Ingredient]
    let qualities: Qualities
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case serverError(String)
}

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://sweat-gemini.unleashai-inquiries.workers.dev/"
    
    private init() {}
    
    func analyzePreworkout(imageBase64: String) async throws -> AnalysisResponse {
        guard let url = URL(string: "\(baseURL)/analyze") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["image": imageBase64]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NetworkError.serverError(errorMessage)
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(AnalysisResponse.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
} 