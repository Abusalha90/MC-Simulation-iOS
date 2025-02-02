//
//  ContentView 2.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/7/25.
//

import SwiftUI

struct view_Previegws: PreviewProvider {
    static var previews: some View {
        HomeView(selection: .constant(1))
    }
}

struct HomeView: View {
    @Binding var selection: Int

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView([.vertical], showsIndicators: false) {
                    
                    // Background color
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        AnimationPartView()
                        
                        specialTabButton(selection: $selection, targetTab: 1, title: "Start Simulation")
                        ButtonGridView()
                        NuclearFactCardView()
                        NewsView()
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("Criticality App")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Nuclear Monte Carlo Simulation")
                            .font(.system(size: 20, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .background(.black)
            }
        }
        .preferredColorScheme(.dark)  // Forces dark mode
    }
    
}
