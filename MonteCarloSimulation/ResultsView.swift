//
//  ResultsView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 23/11/2022.
//

import SwiftUI

struct ResultsView: View {
    @State var simulationRunResults:SimulationRun
    var dismiss: (() -> Void)? = nil

    var body: some View {
        VStack {
            HStack {
                Button {
                    dismiss?()
                } label: {
                    Image(systemName: "chevron.backward").foregroundColor(.black)
                }
                Spacer()
                Text("Simulation Results!")
                    .font(.title)
                Spacer()
            }.padding()

            VStack{
                Rectangle().foregroundColor(.blue)
                    .border(.white)
                    .frame(width:20)
                    

                HStack {
                    Text("Simulation Features: ")
                    Text(simulationRunResults.type)
                    Spacer()
                }
                HStack {
                    Text("Run Time = ")
                    Text("\(Int(simulationRunResults.runTime)) seconds ")
                    Spacer()
                }
                HStack {
                    Text("Total # of Interactons = ")
                    Text("\(Int(simulationRunResults.totInteractions))")
                    Spacer()
                }
                HStack {
                    Text("Histories = ")
                    Text(Int(simulationRunResults.histories).description)
                    Spacer()
                }
                HStack {
                    Text("Batches = ")
                    Text(Int(simulationRunResults.batches).description)
                    Spacer()
                }
                HStack {
                    Text("Date = ")
                    Text(simulationRunResults.date.description)
                    Spacer()
                }
            }.padding()
            
            Text("Tallying").fontWeight(.bold)
                .font(.largeTitle)
            Spacer().frame(height: 20)
            ScrollView {
                ForEach(simulationRunResults.tallyResults) { tally in
                    VStack{
                        Text(tally.type)

                        HStack{
                            Text("Mean Value")
                            Spacer()
                            Text(tally.mean.description)
                        }
                        HStack{
                            Text("Variance")
                            Spacer()
                            Text(tally.variance.description)
                        }
                        HStack{
                            Text("Standard Deviation")
                            Spacer()
                            Text(tally.StandardDeviation.description)
                        }
                        HStack{
                            Text("FOM")
                            Spacer()
                            Text(tally.FOM.description)
                        }
                    }.padding()
                    Spacer().frame(height: 20)
                    
                }
            }
            

        }

    }
}

struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        ResultsView(simulationRunResults: SimulationRun.init(type: "Standard MC",date: Date(), histories: 1000,batches: 100,runTime: 15.2, tallyResults: [
            
            Tally(type: "reflected", mean: 0.20916, variance: 3.3081e-07, StandardDeviation: 0.011499, FOM: 11410.84),
            Tally(type: "transmission", mean: 0.00035, variance: 3.3081e-07, StandardDeviation: 0.0005751592, FOM: 4561351.3),
            Tally(type: "absorption", mean: 0.79049, variance: 0.00013609, StandardDeviation: 0.011665797, FOM: 11087.68)
        ]))
    }
}
