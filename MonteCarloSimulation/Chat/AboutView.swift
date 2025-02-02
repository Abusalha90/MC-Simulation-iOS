//
//  AboutView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 2/2/25.
//
import SwiftUI

struct AboutView: View {
    var body: some View {
        Form {
            Section("AI Technology") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This app uses DeepSeek AI")
                        .font(.headline)
                    
                    Text("DeepSeek is an advanced artificial intelligence system that powers the conversational capabilities in this app. It provides natural language understanding and generation capabilities.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Link("Learn more about DeepSeek", 
                         destination: URL(string: "https://www.deepseek.com")!)
                        .font(.subheadline)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("About")
    }
}
