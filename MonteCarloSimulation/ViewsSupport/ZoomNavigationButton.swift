//
//  MyNavigationButtonIcon.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/17/25.
//

import SwiftUI
import SwiftUIJoystick

struct ZoomNavigationButton<Destination: View>: View {
    @Namespace private var animationNamespace
    var icon: String
    var destination: Destination
    var body: some View {
        NavigationStack {
            if #available(iOS 18.0, *) {
                NavigationLink(destination: destination
                    .navigationTransition(.zoom(sourceID: icon,
                                                in: animationNamespace))
                ) {
                    Image(systemName: icon)
                        .foregroundColor(Color.accentRadiation)
                        .padding(10)
                        .background(Color.secondaryColor)
                        .clipShape(Circle())
                        .matchedGeometryEffect(id: icon, in: animationNamespace)
                }
            } else {
                // Fallback on earlier versions
            }
            
        }
    }
}
