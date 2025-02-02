//
//  CommunityChatView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/24/25.
//


import SwiftUI
import Firebase

struct CommunityChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var selectedDate: Date? = Date() // Track the selected date

    var body: some View {
        VStack {
            // Date picker dropdown for available dates
            if !viewModel.availableDates.isEmpty {
                Picker("Select Date", selection: $selectedDate) {
                    ForEach(viewModel.availableDates, id: \.self) { date in
                        Text(formatDate(date)) // Display formatted date
                            .tag(date as Date?)
                    }
                }
                .pickerStyle(MenuPickerStyle()) // Use a dropdown menu style
                .padding()
                
                Button("Load Messages") {
                    if let date = selectedDate {
                        viewModel.fetchMessages(for: date) // Fetch messages for the selected date
                    }
                }
                .disabled(selectedDate == nil) // Disable button if no date is selected
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        // Pull-to-refresh or scroll-to-top to load previous day's messages

                        ForEach(viewModel.communityMessages) { message in
                            HStack {
                                if message.role == "user" {
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        if let userName = message.userName, !userName.isEmpty {
                                            Text(userName)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Text(message.content)
                                            .padding()
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(8)
                                            .frame(maxWidth: 250, alignment: .trailing)
                                    }
                                    .padding(.horizontal)
                                } else {
                                    VStack(alignment: .leading) {
                                        if let userName = message.userName, !userName.isEmpty {
                                            Text(userName)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Text(message.content)
                                            .padding()
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(8)
                                            .frame(maxWidth: 250, alignment: .leading)
                                    }
                                    .padding(.horizontal)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .id(message.id)
                        }
                    }
                }
                .onChange(of: viewModel.communityMessages) { _, _ in
                    if let lastMessage = viewModel.communityMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            if viewModel.remainingMessages > 0 {
                VStack {
                    // Show remaining message count
                    Text("Remaining messages: \(viewModel.remainingMessages)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    HStack {
                        TextField("Type your message...", text: $viewModel.userInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        Button(action: {
                            viewModel.sendMessageToCommunity()
                            viewModel.decrementMessageCount(for: "messages")
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                                .padding()
                        }
                        .disabled(viewModel.userInput.isEmpty)
                    }
                    .padding(.bottom)

                }
            } else {
                // Show message limit reached UI
                Text("You've reached your daily limit of \(viewModel.maxMessagesPerDay) messages. Come back tomorrow!")
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .dismissKeyboardOnTap()
        .onAppear(perform: viewModel.fetchMessagesForToday)
    }
    
    // Helper function to format the date
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
