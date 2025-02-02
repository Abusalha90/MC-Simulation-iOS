//
//  ChatMessage.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 2/2/25.
//
import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let role: String // "user" or "assistant"
    let content: String
    let userName: String?
    var timestamp: Date?
}

struct DeepSeekResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
