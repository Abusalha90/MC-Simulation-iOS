//
//  ParticleFullView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/25/25.
//

import SwiftUI


struct ParticleFullView_Previews: PreviewProvider {
    static var previews: some View {
        ParticleFullView()
    }
}

struct ParticleFullView: View {
    @State private var gridSize: CGFloat = 300
    @State private var particleCount: Int = 150
    @State private var particleCountDouble: Double = 150 // Temporary Double binding for Slider
    @State private var animationSpeed: Double = 5
    @State private var animationSlider: Double = 5

    @State private var backgroundColor: Color = Color.black

    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)

            VStack {
                
                // Particle View with grid size and particle count
                ParticleView(animationSpeed: $animationSpeed, gridSize: $gridSize, particleCount: $particleCount)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Controls for adjusting grid size, particle count, and animation speed
                VStack(spacing: 20) {
                    HStack {
                        Text("Atom Size")
                        Slider(value: $gridSize, in: 50...400, step: 10)
                        .accentColor(Color.accentRadiation)
                    }
                    
                    HStack {
                        Text("Particles")
                        Slider(value: $particleCountDouble, in: 5...500, step: 10)
                        .accentColor(Color.accentRadiation)
                        .onChange(of: particleCountDouble) { _,newValue in
                            particleCount = Int(newValue) // Convert Double to Int when updating
                        }
                        
                    }
                    
                    HStack {
                        Image(systemName: "tortoise.fill")
                            .foregroundColor(Color.secondaryColor)
                        
                        Slider(value: $animationSlider, in: 1.0...10.0) { _ in
                            // Adjust the slider value to work as decreasing when moving right
                        }
                        .accentColor(Color.accentRadiation)
                        .onChange(of: animationSlider) { _,newValue in
                            // Flip the value based on the range
                            let flippedValue = 12.0 - newValue // Reverses the value in the range 2.0...10.0
                            animationSpeed = flippedValue
                        }
                       
                        Image(systemName: "hare.fill")
                            .foregroundColor(Color.primaryColor)
                    }
                    
                    // Background color picker to change the theme
                    ColorPicker("Background Color", selection: $backgroundColor)
                        .padding()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.8)))
                .shadow(radius: 10)
            }
            .edgesIgnoringSafeArea(.all)
            .animation(.easeInOut(duration: 0.5), value: animationSpeed)
        }  // Smooth animation transitions
    }
}
