//
//  ChatModel+DeepSeek.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 2/2/25.
//
import SwiftUI
import Foundation

// DeepSeek functions
extension ChatViewModel {
    // Updated save/load methods for DeepSeek
    func saveDeepSeekHistory() {
        if let encodedData = try? JSONEncoder().encode(DeepSeekMessages) {
            UserDefaults.standard.set(encodedData, forKey: "deepSeekChatHistory")
        }
    }
    
    func loadDeepSeekHistory() {
        if let savedData = UserDefaults.standard.data(forKey: "deepSeekChatHistory") {
            if let savedChatHistory = try? JSONDecoder().decode([ChatMessage].self, from: savedData) {
                DeepSeekMessages = savedChatHistory
            }
        }
    }
    
    // Add to your existing clearChatHistory
    func clearDeepSeekHistory() {
        DeepSeekMessages.removeAll()
        saveDeepSeekHistory()
    }
    
    // Add this new method for DeepSeek interactions
    func sendDeepSeekMessage() async {
        guard !userInput.isEmpty, !isLoading, remainingAIRequests > 0 else { return }
        isLoading = true

        let userMessage = ChatMessage(
            role: "user",
            content: userInput,
            userName: userName,
            timestamp: Date()
        )
        
        // Add temporary loading message
        let tempAIMessage = ChatMessage(
            role: "assistant",
            content: "...",
            userName: "DeepSeek AI",
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.DeepSeekMessages.append(userMessage)
            self.DeepSeekMessages.append(tempAIMessage)
            self.userInput = ""
        }
        
        do {
            let response = try await deepSeek.sendMessage(messages: DeepSeekMessages.filter { $0.content != "..." })
            
            DispatchQueue.main.async {
                if let lastIndex = self.DeepSeekMessages.lastIndex(where: { $0.content == "..." }) {
                    self.DeepSeekMessages[lastIndex] = ChatMessage(
                        role: "assistant",
                        content: response,
                        userName: "DeepSeek AI",
                        timestamp: Date()
                    )
                }
                self.decrementMessageCount(for: "ai")
                self.saveDeepSeekHistory()
            }
        } catch {
            DispatchQueue.main.async {
                self.DeepSeekMessages.removeLast()
                self.userInput = userMessage.content
                // Handle error state as needed
            }
        }
        
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }

}
