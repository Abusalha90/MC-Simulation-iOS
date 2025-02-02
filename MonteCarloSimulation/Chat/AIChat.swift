//
//  Conversation.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 2/2/25.
//


import SwiftUI
import SwiftData

#Preview {
    DeepSeekChatView(viewModel: ChatViewModel())
}
// MARK: - Chat View (Updated)
struct DeepSeekChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        NavigationView {
            
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack {
                            ForEach(viewModel.ActiveMessages) { message in
                                HStack {
                                    if message.role == "user" {
                                        Spacer()
                                        Text(message.content)
                                            .padding()
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(8)
                                            .frame(maxWidth: 250, alignment: .trailing)
                                            .textSelection(.enabled)
                                    } else if message.role == "assistant" {
                                        Text(message.content)
                                            .padding()
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(8)
                                            .frame(maxWidth: 250, alignment: .leading)
                                            .textSelection(.enabled)
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                                .id(message.id) // Assign each message a unique ID
                                
                            }
                        }
                    }
                    .onChange(of: viewModel.ActiveMessages, { oldValue, newValue in
                        // Scroll to the latest message when a new one is added
                        if let lastMessage = viewModel.ActiveMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom) // Ensure `.id` is correctly assigned
                            }
                        }
                    })
                }
                
                if viewModel.remainingAIRequests > 0 {
                    HStack {
                        TextField("Type your question...", text: $viewModel.userInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.trailing)
                        } else {
                            Button {
                                Task { await viewModel.sendMessages() }
                            } label: {
                                Image(systemName: "paperplane.fill")
                            }
                            .disabled(viewModel.userInput.isEmpty)
                        }
                    }
                    .padding()
                } else {
                    Text("You've reached your daily limit of \(viewModel.maxAIMessagesPerDay) messages. Come back tomorrow!")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Text("AI requests remaining: \(viewModel.remainingAIRequests)")
                    .font(.caption)
                
                Text("Powered by \(viewModel.selectedModel)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
//            .dismissKeyboardOnTap() // Apply the custom modifier here
            .onAppear {
                viewModel.checkDailyLimit()
            }
        }
    }
}
