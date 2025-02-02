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
    @State var scale : CGFloat = 1.0
    @State var KeffScale : CGFloat = 1.0
    @State var tallyType : TallyEst = .collision
    
    var body: some View{
        
        ScrollView{
            VStack{
                
                GroupBox("Fission Source Distribution N=\(Int(object.history))") {
                    ScrollView(.horizontal) {
                        Chart{
                            ForEach(Array(object.fissionDistrDraw.enumerated()),id: \.offset){ (i,val) in
                                BarMark(x: .value("xx", val.key),
                                        y: .value("yy", val.value.count)
                                )
                            }
                            .foregroundStyle(.green)
                        }.frame(width:UIScreen.main.bounds.width*scale,height:150)
                            .chartXAxis {
                                AxisMarks(values: [0,10,20,30,40,50,60,70,80,90,100])
                            }

                            .scaleEffect(x: scale)
                            .gesture(MagnificationGesture()
                            .onChanged { value in
                                self.scale = value.magnitude
                            }
                        )
                    }
                }
                
                GroupBox("Keff per Cycle: \(object.KeffText)") {
                    Chart{
                        ForEach(Array(object.Keff_CyclesAvg.enumerated()),id: \.offset){ (i,val) in
                            LineMark(x: .value("xxx", i),
                                     y: .value("coll", val)
                            )
                        }
                        .foregroundStyle(by: .value("Keff0", "Average=\(String(format: "%.5f", object.Keff_CyclesAvg.last ?? 0.0) )"))
                        
                        ForEach(Array(object.Keff_Cycles1.enumerated()),id: \.offset){ (i,val) in
                            LineMark(x: .value("xxx", i),
                                     y: .value("track", val)
                            )
                        }
                        .foregroundStyle(by: .value("Keff1", "Collision=\(String(format: "%.5f", object.Keff_Cycles1.last ?? 0.0) )"))
                        
                        ForEach(Array(object.Keff_Cycles2.enumerated()),id: \.offset){ (i,val) in
                            LineMark(x: .value("xxx", i),
                                     y: .value("track", val)
                            )
                        }
                        .foregroundStyle(by: .value("Keff2", "Absorption=\(String(format: "%.5f", object.Keff_Cycles2.last ?? 0.0) )"))

                        ForEach(Array(object.Keff_Cycles3.enumerated()),id: \.offset){ (i,val) in
                            LineMark(x: .value("xxx", i),
                                     y: .value("track", val)
                            )
                        }
                        .foregroundStyle(by: .value("Keff3", "Track Length=\(String(format: "%.5f", object.Keff_Cycles3.last ?? 0.0) )"))

                    }.frame(height:150)
                    
                        .chartYScale(domain: (KeffScale*((object.Keff_CyclesAvg.last ?? 0.0) - 0.1))...(((object.Keff_CyclesAvg.last ?? 1.0) + 0.1)*KeffScale))
                        .scaleEffect(y: KeffScale)
                        .gesture(MagnificationGesture()
                        .onChanged { value in
                            self.KeffScale = value.magnitude
                        }
                    )
                        .padding([.leading,.trailing], 4)
                        .clipped()
                    
                }
                
                if object.cyclesTallies.count > 0{
                    HStack{
                        Text("Tally Type ")
                        Picker("", selection: $tallyType) {
                            ForEach(TallyEst.allCases, id: \.self) { value in
                                Text(value.name)
                                    .tag(value)
                            }
                        }
                        .pickerStyle(.menu)
                    }.padding()
                    
                    TallyChart(tallyType:$tallyType, tallies: $object.cycleTallies,groups:$object.energyGroups)
                }
            }
        }
    }
}


struct TallyChart: View {
    
    @Binding var tallyType:TallyEst
    @Binding var tallies:CycleTallies
    @Binding var groups : Int
    @State var showTotal : Bool = false
    var symbols : [BasicChartSymbolShape] = [.triangle,.circle,.square,.diamond,.cross,.triangle,.circle,.square,.diamond,.cross]

    
    func tallyFilter() -> [[fluxTally]]{
        let targetTally = (tallyType == .current || tallyType == .surfaceAvg) ? tallies.surface:tallies.cell
        let tallies = targetTally.map{$0.filter({$0.type == tallyType})}.filter {$0.count != 0}
        return tallies
    }
    
    var body: some View {
        GroupBox(tallyType.name) {
            Chart{
                ForEach(Array(tallyFilter().enumerated()),id: \.offset){ (i,val) in
                    LineMark(x: .value("region", i),
                             y: .value("Total flux", val.map{$0.score}.reduce(0,+)))
                }
                .foregroundStyle(by: .value("1", "Total Flux"))
                .symbol(.square)
                
                ForEach(Array(Range(0...groups-1)),id:\.self){ g in
                    ForEach(Array(tallyFilter().enumerated()), id: \.offset){ (i,region) in
                        LineMark(x: .value("Value #/cm",i),
                                 y: .value("Group: \(g)",region[g].score))
                    }
                    .foregroundStyle(by: .value("2", "Group \(g)"))
                    .symbol(symbols[g])
                }
            }.frame(height:250)
        }
    }
}

