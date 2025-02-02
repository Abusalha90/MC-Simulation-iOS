//
//  ChatModel+Firebase.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 2/2/25.
//
//
import Foundation
import Firebase
import FirebaseAuth

// Comunity firebase
extension ChatViewModel {
    
    func fetchMessagesForToday() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd"
        let todayString = dateFormatter.string(from: currentlyDisplayedDate)
        
        let db = Firestore.firestore()
        db.collection("communityChat").document(todayString).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    self.communityMessages = documents.compactMap { doc in
                        let data = doc.data()
                        guard let content = data["content"] as? String,
                                let role = data["role"] as? String,
                                let userName = data["userName"] as? String else { return nil }
                        return ChatMessage(role: role, content: content, userName: userName)
                    }
                }
            }
    }
    
    func fetchMessages(for date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd"
        let dateString = dateFormatter.string(from: date)

        let db = Firestore.firestore()
        db.collection("communityChat").document(dateString).collection("messages")
            .order(by: "timestamp")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching messages for \(dateString): \(error.localizedDescription)")
                    return
                }

                if let documents = snapshot?.documents {
                    self.communityMessages = documents.compactMap { doc in
                        let data = doc.data()
                        guard let content = data["content"] as? String,
                              let role = data["role"] as? String else { return nil }
                        return ChatMessage(role: role, content: content, userName: data["userName"] as? String)
                    }
                }
            }
    }

    func fetchAvailableDates() {
        let db = Firestore.firestore()
        db.collection("communityChat").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching available dates: \(error.localizedDescription)")
                return
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy_MM_dd"

            // Convert document IDs (representing dates) to Date objects
            self.availableDates = snapshot?.documents.compactMap { doc in
                dateFormatter.date(from: doc.documentID)
            } ?? []
            
            // Sort dates in descending order (latest first)
            self.availableDates.sort(by: >)
        }
    }

    func sendMessageToCommunity() {
        guard !userInput.isEmpty else { return }
        
        let db = Firestore.firestore()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd"
        let todayString = dateFormatter.string(from: currentlyDisplayedDate)
        
        let newMessage: [String: Any] = [
            "userName": Auth.auth().currentUser?.displayName ?? userName,
            "content": userInput,
            "role": "user",
            "timestamp": Timestamp(date: Date())
        ]
        
        db.collection("communityChat").document(todayString).collection("messages")
            .addDocument(data: newMessage) { error in
                if let error = error {
                    print("Error sending message: \(error.localizedDescription)")
                } else {
                    self.userInput = ""
                    self.decrementMessageCount(for: "message")
                }
            }
        
    }

}
