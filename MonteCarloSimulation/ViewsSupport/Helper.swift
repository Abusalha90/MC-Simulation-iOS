//
//  Helper.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/12/25.
//

import SwiftUI

struct TextFieldSection: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct myNavigationButton<Destination: View>: View {
    var title: String
    var icon: String
    var destination: Destination
    var gradient: Gradient? = Gradient(colors: [Color.blue, Color.purple])
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.vertical, 15)
                    .padding(.leading, 10)
                    .frame(maxWidth: .infinity)
            }
            .background(
                LinearGradient(gradient: gradient!, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .cornerRadius(15)
            )
            .shadow(radius: 10)
        }
        .padding()
    }
}

struct specialTabButton: View {
    @Binding var selection: Int
    let targetTab: Int
    var title: String
    var body: some View {
        Button(action: {
            selection = targetTab
        }) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.vertical, 15)
                    .padding(.leading, 10)
                    .frame(maxWidth: .infinity)
            }
            .background(
                LinearGradient(gradient: Gradient.appGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .cornerRadius(15)
            )
            .shadow(radius: 10)
        }
    }
}

// Custom Transition Modifier
extension AnyTransition {
    static var scale: AnyTransition {
        .modifier(
            active: ScaleOpacityModifier(scale: 0.1, opacity: 0),
            identity: ScaleOpacityModifier(scale: 1, opacity: 1)
        )
    }
}

struct ScaleOpacityModifier: ViewModifier {
    let scale: CGFloat
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
    }
}

struct DismissKeyboardOnTap: ViewModifier {
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        print("dismiss keyboard")
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                Color.clear
                    .contentShape(Rectangle()) // Ensure the background is tappable
                    .onTapGesture {
                        hideKeyboard()
                    }
            )
    }
    
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

