//
//  ChartsView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 23/12/2022.
//

import SwiftUI
import Charts

struct ChartsView: View {
    @ObservedObject var object : Criticality_Sim
    @Binding var tallies : [[fluxTally]]
    
    var symbols : [BasicChartSymbolShape] = [.triangle,.circle,.square,.diamond,.cross]
    func collisionTalliess() -> [[fluxTally]]{
        let tallies = tallies.map{$0.filter({$0.type == .collision})}
//        var gs = [Int]()
//        for g in groups{
//            if tallies.map({$0[g].score}).reduce(0,+) == 0.0 {
//                gs.append(g)
//            }
//        }
//        tallies = tallies.map{($0.filter({gs.contains($0.group.rawValue)}))}

        
        return tallies
    }
    
    var groups : [Int] {
        return Array(Range(0...(energyGroup.allCases.count-1)))
    }
    
    
    var body: some View{
        
        ScrollView{
            VStack{
                
                GroupBox("Fission Source Distribution N=\(Int(object.history))") {
                    Chart{
                        ForEach(Array(object.fissionDistrDraw.enumerated()),id: \.offset){ (i,val) in
                            BarMark(x: .value("xx", val.key),
                                    y: .value("yy", val.value.count)
                            )
                        }
                        .foregroundStyle(.green)
                    }.frame(height:150)
                        .chartXAxis {
                            AxisMarks(values: [0,10,20,30,40,50,60,70,80,90,100])
                        }
                }
                
                GroupBox("Keff per Cycle: \(object.KeffText)") {
                    Chart{
                        ForEach(Array(object.Keff_Cycles0.enumerated()),id: \.offset){ (i,val) in
                            LineMark(x: .value("xxx", i),
                                     y: .value("stnrd", val)
                            )
                        }
                        .foregroundStyle(by: .value("Keff0", "Standard=\( object.Keff_Cycles0.last ?? 0.0 ),"))

                        ForEach(Array(object.Keff_Cycles.enumerated()),id: \.offset){ (i,val) in
                            LineMark(x: .value("xxx", i),
                                     y: .value("coll", val)
                            )
                        }
                        .foregroundStyle(by: .value("Keff1", "Collision"))
                        
                        ForEach(Array(object.Keff_Cycles3.enumerated()),id: \.offset){ (i,val) in
                            LineMark(x: .value("xxx", i),
                                     y: .value("track", val)
                            )
                        }
                        .foregroundStyle(by: .value("Keff2", "Track Length"))


                    }.frame(height:150)
                    
                        .chartYScale(domain: ((object.Keff_Cycles.last ?? 0.0) - 0.1)...((object.Keff_Cycles.last ?? 1.0) + 0.1))
                        .padding([.leading,.trailing], 4)
                        .clipped()
                    
                }
                
                if object.cyclesTallies.count > 0{
                    
                    GroupBox("Collision Flux Estimator") {
                        Chart{
                            ForEach(Array(tallies.enumerated()),id: \.offset){ (i,val) in
                                LineMark(x: .value("region", i),
                                         y: .value("Total flux", val.filter({$0.type == .collision}).map{$0.score}.reduce(0,+)))
                                
                            }
                            .foregroundStyle(by: .value("Cycle \(object.currentCycle)", "Total Flux"))
                            .symbol(.square)
                            
                            
                            ForEach(groups,id:\.self){ g in
                                
                                ForEach(Array(collisionTalliess().enumerated()), id: \.offset){ (i,region) in
                                    LineMark(x: .value("Value #/cm",i),
                                             y: .value("Group: \(g)",region[g].score))
                                    
                                }
                                
                                .foregroundStyle(by: .value("Cycle \(object.currentCycle)", "Group \(g)"))
                                
                                .symbol(symbols[g])
                            }
            
                        }.frame(height:250)

                    }
                    
                    GroupBox("Track Length Flux Estimator"){
                        Chart{
                            ForEach(Array(tallies.enumerated()),id: \.offset){ (i,val) in
                                
                                LineMark(x: .value("region", i),
                                         y: .value("Total flux", val.filter({$0.type == .length}).map{$0.score}.reduce(0,+))
                                )
                                
                            }
                            .foregroundStyle(by: .value("Cycle \(object.currentCycle)", "Total Flux"))
                            //                        .foregroundStyle(.black)
                            .symbol(.square)
                            
                            ForEach(Array(tallies.enumerated()),id: \.offset){ (i,val) in
                                
                                LineMark(x: .value("region", i),
                                         y: .value("fast", val.first(where: {$0.type == .length && $0.group == .group0 })!.score)
                                )
                                
                            }
                            .foregroundStyle(by: .value("Cycle \(object.currentCycle)", "Fast Flux"))
                            .symbol(.triangle)
                            
                            
                            ForEach(Array(tallies.enumerated()),id: \.offset){ (i,val) in
                                LineMark(x: .value("region", i),
                                         y: .value("thermal", val.first(where: {$0.type == .length && $0.group == .group1 })!.score))
                            }
                            .foregroundStyle(by: .value("Cycle \(object.currentCycle)", "Thermal Flux"))
                            .symbol(.circle)
                            
                        }.frame(height:250)
                        
                        //                        .chartForegroundStyleScale(["Total Flux":.black,"Fast Flux":.blue,"Thermal Flux":.green])
                    }
                    
                    GroupBox("Total Flux,  Track length vs Collision Estimator"){
                        Chart{
                            ForEach(Array(tallies.enumerated()),id: \.offset){ (i,val) in
                                LineMark(x: .value("region", i),
                                         y: .value("Total flux", val.filter({$0.type == .length}).map{$0.score}.reduce(0,+))
                                )
                            }
                            .foregroundStyle(by: .value("Cycle \(object.currentCycle)", "Track length"))
                            .symbol(.square)
                            
                            
                            ForEach(Array(tallies.enumerated()),id: \.offset){ (i,val) in
                                LineMark(x: .value("region", i),
                                         y: .value("Total flux", val.filter({$0.type == .collision}).map{$0.score}.reduce(0,+))
                                )
                            }
                            .foregroundStyle(by: .value("Cycle \(object.currentCycle)", "Collision"))
                            .symbol(.triangle)
                        }
                    }
                    GroupBox("Surface Current"){
                        
                    }
                }
            }
        }
    }
}
