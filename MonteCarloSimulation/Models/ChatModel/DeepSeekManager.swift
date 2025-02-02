//
//  DeepSeekManager.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 2/2/25.
//
import Foundation

// MARK: - Network Manager
class DeepSeekManager {
    static let shared = DeepSeekManager()
    private let apiKey = "your-api-key-here"
    private let baseURL = "https://api.deepseek.com/v1/chat/completions"
    
    func sendMessage(messages: [ChatMessage]) async throws -> String {
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let history = messages.map { ["role": $0.role, "content": $0.content] }
        
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": history,
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let result = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
        return result.choices.first?.message.content ?? "No response"
    }
}
