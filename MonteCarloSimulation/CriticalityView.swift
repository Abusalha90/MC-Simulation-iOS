//
//  CriticalityView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 11/12/2022.
//

import SwiftUI
import Charts

struct CriticalityView_Previews: PreviewProvider {
    static var previews: some View {
        CriticalityView(object: Criticality_Sim())
    }
}

struct CriticalityView: View {
    @ObservedObject var object : Criticality_Sim
    
    @State var steps:Int = 1
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ZStack{
                ScrollView {
                    VStack {
                        VStack{
                            Text("Monte Carlo Simulation")
                            Text("KAIST")
                            Text("1D SLAB REACTOR")
                            GeometryView(object:object)
                            
                            HStack{
                                VStack{
                                    Text("Initial \nKeff")
                                    TextField("", value: $object.KeffText,formatter: formatter )
                                        .textFieldStyle(.roundedBorder)
                                        .multilineTextAlignment(.center)
                                }
                                VStack {
                                    Text("Neutron \nHistories")
                                    TextField("##", value: $object.history,formatter: NumberFormatter())
                                        .textFieldStyle(.roundedBorder)
                                        .multilineTextAlignment(.center)

                                }
                                
                                VStack {
                                    Text("Active \nCycles")
                                    TextField("##", value: $object.cycles,formatter: NumberFormatter())
                                        .textFieldStyle(.roundedBorder)
                                        .multilineTextAlignment(.center)
                                }
                                VStack {
                                    Text("InActive \nCycles")
                                    TextField("##", value: $object.inactiveC,formatter: NumberFormatter())
                                        .textFieldStyle(.roundedBorder)
                                        .multilineTextAlignment(.center)
                                }
                                
                            }.padding()
                            
                            Toggle(isOn: $object.isImpliciteCapture) {
                                Text("Use Implicite Capture")
                            }.padding()
                            Toggle(isOn: $object.animationEnabled) {
                                Text("Enable Animation")
                            }.padding()
                            
                        }
                        
                        Button {
                            if !object.isRunning{
                                object.run()
                            }
                        } label: {
                            if !object.isRunning{
                                Text("Start Simulation")
                            } else {
                                ProgressView()
                            }
                            
                        }
                        
                        Picker(selection: $object.initialSource, label: Text("Initial SOurce")) {
                            Text("Point Src").tag(0)
                            Text("Normal Distribution Src").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        
                    }
                    if !object.isRunning{
                        ChartsView(object: object, tallies: $object.cycleTallies)
                    }
                }
                
                if object.isRunning{
                    Color.white.opacity(0.99)
                    
                    ScrollView{
                        VStack{
                            Text("Running in progress")
                            Spacer().frame(height: 50)
                            
                            HStack{
                                Text("Current cycle # ")
                                Spacer()
                                Text(object.currentCycle.description)
                            }
                            Toggle(isOn: $object.animationEnabled) {
                                Text("Enable Animation")
                            }.padding()

                            if object.animationEnabled{

                                ParticleVisualization(object: object).frame(height: 540)
                                   
                            }
                        
                            ChartsView(object: object,tallies: $object.cycleTallies)
                            
                            Button {
                                object.stopSimulation()
                            } label: {
                                Text("Shutdown Simulation")
                            }
                            
                        }.padding()
                    }
                    
                }
            }
        }
    }
}
