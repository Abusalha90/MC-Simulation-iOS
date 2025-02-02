//
//  Extensions.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/12/25.
//
import SwiftUI

// Random color for simulation
extension Color {
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
    
    static let backgroundColors = Color("BackgroundColors")
    
    // Main Brand Colors
    static let primaryColor = Color("PrimaryColor") // Matches the asset catalog name
    static let secondaryColor = Color("SecondaryColor")
    
    static let accentRadiation = Color("AccentRadiation")
    static let accentRed = Color("AccentRed")
    
    // Text Colors
    static let textColors = Color("TextColors") // Default text color
    static let primaryForeground = Color("PrimaryForeground") // Text on primary background
    static let secondaryForeground = Color("SecondaryForeground") // Text on secondary background

}

extension Gradient {
    static var appGradient: Gradient {
        return Gradient(colors: [Color.primaryColor.opacity(0.7), Color.secondaryColor.opacity(0.7)])    }
}

