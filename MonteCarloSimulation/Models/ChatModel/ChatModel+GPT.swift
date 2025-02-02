//
//  File.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 2/2/25.
//
import Foundation
import OpenAI

// chatGPT functions
extension ChatViewModel {
    func openAIClient() -> OpenAI {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "OpenAIAPIKey") as? String ?? ""
        print("API Key: \(apiKey)") // Use this to pass the key to your OpenAI library
        return OpenAI(apiToken: apiKey ) // Replace with your OpenAI API Key
    }
    
    func loadChatHistory() {
        if let savedData = UserDefaults.standard.data(forKey: "chatHistory") {
            if let savedChatHistory = try? JSONDecoder().decode([ChatMessage].self, from: savedData) {
                ChatGPTMessages = savedChatHistory
            }
        }
    }
    
    func saveChatHistory() {
        if let encodedData = try? JSONEncoder().encode(ChatGPTMessages) {
            UserDefaults.standard.set(encodedData, forKey: "chatHistory")
        }
    }
    
    func clearChatHistory() {
        ChatGPTMessages.removeAll()
        saveChatHistory()
    }
    
    func sendMessageToChatGPT() async {
        guard !userInput.isEmpty, remainingAIRequests > 0 else { return }
        
        let aiRole =
        """
        you are the great scientis einstein, you will answer questions related to nuclear science and engineering, specially in the new generation of nuclear power plants, in addition to questions related calculation methods like Monte Carlo methods
        """
        
        let userMessage = ChatMessage(
            role: "user",
            content: userInput,
            userName: userName,
            timestamp: Date()
        )
        let systemMessage = ChatMessage(
            role: "system",
            content: aiRole,
            userName: "Einstein",
            timestamp: Date()
        )

        DispatchQueue.main.async { [self] in
            
            ChatGPTMessages.append(systemMessage)
            ChatGPTMessages.append(userMessage)
            userInput = ""
            isLoading = true
        }
        
        let queryMessages = ChatGPTMessages.compactMap { message in
            ChatQuery.ChatCompletionMessageParam(
                role: message.role == "user" ? .user : .system,
                content: message.content
            )
        }
        // Prepare and send the query
        let query = ChatQuery(messages: queryMessages, model: .gpt4_o_mini)
        
        
        openAIClient().chats(query: query) { result in
            DispatchQueue.main.async { [self] in
                switch result {
                case .success(let response):
                    if let content = response.choices.first?.message.content?.string {
                        let assistantMessage = ChatMessage(role: "assistant", content: content, userName: userName)
                        ChatGPTMessages.append(assistantMessage)
                    } else {
                        ChatGPTMessages.append(ChatMessage(role: "assistant", content: "No response received.", userName: userName))
                    }
                    saveChatHistory()
                case .failure(let error):
                    ChatGPTMessages.append(ChatMessage(role: "assistant", content: "Error: \(error.localizedDescription)", userName: userName))
                }
                isLoading = false
                decrementMessageCount(for: "ai")
                saveChatHistory()
            }
        }
    }
}
