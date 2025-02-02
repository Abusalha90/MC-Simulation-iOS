//
//  ButtonGridView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/17/25.
//


import SwiftUI

struct ButtonGridView: View {
    var body: some View {
        Grid(alignment: .center, horizontalSpacing: 20, verticalSpacing: 20) {
            GridRow {
                myGridButton(title: "Nuclear Timeline", icon: "book",
                                       destination: NuclearTimelineView())

                myGridButton(title: "Nuclear Timeline", icon: "book.fill",
                                       destination: NuclearTimelineView())
            }
            GridRow {
                myGridButton(title: "Nuclear Colision\n3D View", icon: "atom",
                                       destination: ParticleCollisionView())

                myGridButton(title: "Nuclear Systems\n3D View", icon: "scale.3d",
                                       destination: Nuclear3DView())

                
            }
        }
        .padding()
    }
}


struct ContentrwView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonGridView()
    }
}

struct myGridButton<Destination: View>: View {
    var title: String?
    var icon: String?
    var destination: Destination
    var body: some View {
        NavigationLink(destination: destination) {
            VStack {
                Image(systemName: icon ?? "")
                    .font(.largeTitle)
                    .foregroundColor(Color.accentRadiation)
                    .padding(10)
                    .background(Color.secondaryColor)
                    .clipShape(Circle())
                    .frame(width: 50, height: 50)   
                
                Text(title ?? "")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.vertical, 15)
                    .padding(.leading, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient.appGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .cornerRadius(15)
        )
        .shadow(radius: 10)
        .cornerRadius(20)
    }
}
