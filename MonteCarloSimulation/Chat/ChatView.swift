//
//  ChatType.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/24/25.
//

import SwiftUI

#Preview {
    ChatView()
}
enum ChatType: String, CaseIterable, Identifiable {
    case askEinstein = "Ask Einstein"
    case community = "Community"

    var id: String { rawValue }
}


struct ChatView: View {
    
    @State private var selectedChat: ChatType = .askEinstein
    @StateObject private var chatModel = ChatViewModel()

    var body: some View {
        NavigationView {
            VStack {
                // Segmented control
                Picker("Chat Type", selection: $selectedChat) {
                    ForEach(ChatType.allCases) { chatType in
                        Text(chatType.rawValue).tag(chatType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedChat == .askEinstein {
                    DeepSeekChatView(viewModel: chatModel)
//                    ChatGPTAI(viewModel: chatModel)
                } else if selectedChat == .community {
                    CommunityChatView(viewModel: chatModel)
                }
                
            }
    
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Image("einstein")
                        Text("Hi \(chatModel.userName)")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Name") {
                            chatModel.isEditingName = true // Trigger name-editing dialog
                        }
                        // Dynamic menu items based on the selected view
                        if selectedChat == .askEinstein {
                           
                            Button("Clear Einstein History") {
                                chatModel.clearChatHistory()
                            }
                            
                            Button {
                                AboutView()
                            } label: {
                                Label("About", systemImage: "info.circle")
                            }

                            Button("Future Action Einstein") {


                            }
                        } else if selectedChat == .community {
                            Button("Clear Community History") {
//                                chatModel.clearChatHistory()
                            }

                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90)) // Vertical dots style
                    }
                    .alert("Edit Your Name", isPresented: $chatModel.isEditingName, actions: {
                        TextField("Enter your name", text: Binding(
                            get: { chatModel.userName },
                            set: { chatModel.saveUserName($0) }
                        ))
                        Button("Save", role: .none) {}
                        Button("Cancel", role: .cancel) {}
                    }, message: {
                        Text("Enter the name you'd like to use in the community chat.")
                    })

                }
            }
        }
    }

}
