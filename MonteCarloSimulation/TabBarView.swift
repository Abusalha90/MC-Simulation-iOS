//
//  ContentView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 06/11/2022.
//
import SwiftUI
import Foundation
import Charts

struct view_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
            .preferredColorScheme(.dark)  // Forces dark mode
    }
}


struct TabBarView: View {
    @State public var selection = 0
    @ObservedObject var transport = ImpliciteCapture_simu_data()
    @ObservedObject var criticality = Criticality_Sim()

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                HomeView(selection: $selection).tabItem {Label("Home", systemImage: "atom")}.tag(0)
                CriticalityView(object: criticality).tabItem {Label("Criticality", systemImage: "k.circle")}.tag(1)
                TransportView(obj2: transport).tabItem {Label("Transport", systemImage: "t.circle")}.tag(2)
                ChatView()
                    .tabItem {Label("Chat", systemImage: "bubble.left.and.bubble.right")}.tag(3)
                
                MoreView(resultsObj: transport).tabItem {Label("More", systemImage: "list.bullet")}.tag(4)
            }
        }
    }
}
