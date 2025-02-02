//
//  chatGPT.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/23/25.
//
import Foundation
import SwiftUI
import Firebase
import OpenAI
import FirebaseAuth

class ChatViewModel: ObservableObject {
    @Published var ChatGPTMessages: [ChatMessage] = []
    @Published var DeepSeekMessages: [ChatMessage] = []
    @Published var communityMessages: [ChatMessage] = []
    @Published var availableDates: [Date] = [] // Store available dates for messages
    @Published var isEditingName: Bool = false // To trigger the sheet or alert
    @Published var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "there"// Shared user name
    @Published var userInput: String = "" // Shared user input
    @Published var isLoading: Bool = false // Loading state
    @Published var remainingAIRequests: Int = 5 // Shared message limit
    @Published var remainingMessages: Int = 20 // Shared message limit
    @Published var currentlyDisplayedDate: Date = Date()
    
    // DeepSeek integration
    let deepSeek = DeepSeekManager.shared

    let maxMessagesPerDay = 20
    let maxAIMessagesPerDay = 5
    private var hasCheckedDailyLimit = false // Prevent redundant calls

    @Published var selectedModel : String = "ChatGPT AI"
       
    var ActiveMessages: [ChatMessage] {
        return selectedModel == "DeepSeek AI" ? DeepSeekMessages : ChatGPTMessages
    }
    
    init() {
        checkDailyLimit() // Ensure this is checked only once on app launch
        
        if selectedModel == "DeepSeek AI" {
            loadDeepSeekHistory()
        } else {
            loadChatHistory()
        }
    }
    
    func sendMessages() async {
        if selectedModel == "DeepSeek AI" {
            await sendDeepSeekMessage()
        } else {
            await sendMessageToChatGPT()
        }
    }
    
    func saveUserName(_ name: String) {
        userName = name
        UserDefaults.standard.set(name, forKey: "userName") // Save to storage
    }
    
    func checkDailyLimit() {
        guard !hasCheckedDailyLimit else { return } // Avoid repeated calls
        hasCheckedDailyLimit = true
        
        let lastResetDate = UserDefaults.standard.object(forKey: "lastResetDate") as? Date ?? Date.distantPast
        let currentDate = Date()

        if !Calendar.current.isDate(lastResetDate, inSameDayAs: currentDate) {
            // Reset the daily limits
            UserDefaults.standard.set(currentDate, forKey: "lastResetDate")
            UserDefaults.standard.set(maxMessagesPerDay, forKey: "remainingMessages") // Replace 15 with your daily limit
            UserDefaults.standard.set(maxAIMessagesPerDay, forKey: "remainingAIRequests") // Replace 50 with your daily limit
            remainingMessages = maxMessagesPerDay
            remainingAIRequests = maxAIMessagesPerDay
        } else {
            // Load the existing values
            remainingMessages = UserDefaults.standard.integer(forKey: "remainingMessages")
            remainingAIRequests = UserDefaults.standard.integer(forKey: "remainingAIRequests")
        }
    }
    
    func decrementMessageCount(for type: String) {
        switch type {
        case "ai":
            if remainingAIRequests > 0 {
                remainingAIRequests -= 1
                UserDefaults.standard.set(remainingAIRequests, forKey: "remainingAIRequests")
            }
        case "messages":
            if remainingMessages > 0 {
                remainingMessages -= 1
                UserDefaults.standard.set(remainingMessages, forKey: "remainingMessages")
            }
        default:
            break
        }
    }

    
}
