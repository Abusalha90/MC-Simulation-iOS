//
//  AnimationPartView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/26/25.
//
import SwiftUI

struct AnimationPartView: View {
    @Namespace private var animationNamespace
    var body: some View {
        ZStack() {
            ParticleView(animationSpeed: .constant(5.0), gridSize: .constant(150), particleCount: .constant(100))
            VStack {
                HStack {
                    Button {
                        print("s")
                    } label:{
                        Text("Nuclear\nCriticality")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    Button {
                        print("s")
                    } label:{
                        Text("Keff\n0.9991")
                            .font(.subheadline)
                            .padding()
                            .foregroundColor(Color.red)
                    }
                    .background(Color.white)
                    .cornerRadius(40)
                }
                
                Spacer()
                
                HStack {
                    Button {
                        print("s")
                    } label:{
                        Text("U-235")
                            .font(.subheadline)
                            .padding()
                    }
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(40)
                    Spacer()
                    ZoomNavigationButton(icon: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left",
                                           destination: ParticleFullView())
                }
            }
        }
        .padding()
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}
