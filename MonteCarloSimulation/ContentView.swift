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
    }
}


struct TabBarView: View {
    @State public var selection = 0
    @ObservedObject var transport = ImpliciteCapture_simu_data()
    @ObservedObject var criticality = Criticality_Sim()

    var body: some View {
        TabView(selection: $selection) {
            
            CriticalityView(object: criticality) .tabItem { Text("Criticality") }.tag(1)
            TransportView(obj2: transport) .tabItem { Text("Transport") }.tag(2)
            AllResults(resultsObj: transport).tabItem { Image(systemName: "list.bullet") }.tag(3)
        }
    }
}

struct TransportView: View {
    @ObservedObject var obj = simu_data()
    @ObservedObject var obj2 : ImpliciteCapture_simu_data
    @State var steps:Int = 1

    var body: some View {
        NavigationView {
            ZStack{
                ScrollView {
                    VStack {
                        VStack{
                            Text("Monte Carlo Simulation")
                            Text("KAIST")
                            
                            HStack{
                                VStack {
                                    Text("# Histories")
                                    TextField("# Histories", value: $obj2.histories,formatter: NumberFormatter())
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                VStack {
                                    Text("# Batch")
                                    TextField("# Batch", value: $obj2.batches,formatter: NumberFormatter())
                                        .textFieldStyle(.roundedBorder)
                                }
                            }.padding()
                            Text("# of Volumes").padding()
                        }
                        
                        //                TextField("batch", text: String($obj.batch))
                        
                        Picker(selection: $obj.volumeIndex, label: Text("Picker")) {
                            Text("1").tag(0)
                            Text("2").tag(1)
                            Text("10").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        
                        
                        HStack {
                            ForEach(obj.volumes_Figures,id: \.self) { item in
                                VStack {
                                    Rectangle().foregroundColor(Int(item)%2 == 0 ? .red:.black)
                                        .frame(width:1)
                                    Text((item).description)
                                        .font(.system(size: 10))
                                }
                                .frame(width: UIScreen.main.bounds.width/CGFloat(obj.volumes_Figures.count+5))
                            }
                            
                            
                        }.frame(height: 200)
                            .padding()
                        
                        Button {
                            if !obj2.isRunning{
                                //obj.run()
                                obj2.run()
                            }
                        } label: {
                            if !obj2.isRunning{
                                Text("Start Simulation")
                            } else {
                                ProgressView()
                            }
                            
                        }
                                            
                        Toggle(isOn: $obj2.isImpliciteCapture) {
                            Text("Use Implicite Capture")
                        }.padding()

                        Toggle(isOn: $obj2.isSplitting) {
                            Text("Use splitting")
                        }.padding()
                            
                        
                        Spacer().frame(height: 20)
                        NavigationLink("Draw results") {
                            ExtractedView(arr1:$obj.mean_Coll ,arr2: $obj.mean_Track, volumes_list: obj.volumes_list)
                        }

                    }.fullScreenCover(isPresented: $obj2.showResultsView) {
                        ResultsView(simulationRunResults: obj2.simulationRun.last!){
                            obj2.showResultsView.toggle()
                        }
                    }
                }
                if obj2.isRunning{
                    Color.gray.opacity(0.8)
                   
                    VStack{
                        Text("Running in progress")
                        Spacer().frame(height: 50)
                        
                        if obj2.currentBatch < 9 {
                            HStack{
                                Text("Current Batch # ")
                                Spacer()
                                Text(obj2.currentBatch.description)
                            }
                            HStack{
                                Text("Banked Neutrons")
                                Spacer()
                                Text(obj2.bankedNeutrons.count.description)
                            }
                        }
                       
                        
                    }.padding()
                }
            }
        }
    }
}



struct ExtractedView: View {
    @Binding var arr1 : [Double]
    @Binding var arr2 : [Double]
    
    var volumes_list : [Int] // volume Distance x from its border
    
    var body: some View {
        Chart{
            ForEach(Array(volumes_list.enumerated()),id: \.offset){ (i,vol) in
                LineMark(x: .value("xxx", vol),
                         y: .value("coll", arr1[i])
                )
            }
            .foregroundStyle(.green)
            .foregroundStyle(by: .value("xxx", "coll"))
            ForEach(Array(volumes_list.enumerated()),id: \.offset){ (i,vol) in
                LineMark(x: .value("xxx", vol),
                         y: .value("track", arr2[i])
                )
                
            }
            .foregroundStyle(.red)
            .foregroundStyle(by: .value("xxx", "track"))
            .interpolationMethod(.catmullRom)
            
        }
        //        .foregroundStyle(by: .value("yyy", arr2))
        
        .padding()
        .chartYAxis{
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: volumes_list)
        }
        .frame(height:250)
        
    }
}
