//
//  MoreView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 23/11/2022.
//

import SwiftUI

struct MoreView: View {
    
    @ObservedObject var resultsObj : ImpliciteCapture_simu_data

    var body: some View {
        NavigationView {
            List(Array(zip(resultsObj.simulationRun.indices,resultsObj.simulationRun)),id: \.0){ (i,item) in
                NavigationLink {
                    ResultsView(simulationRunResults: item)
                } label: {
                    Text(item.type)
                    Text(item.date.formatted())
                }
                .swipeActions {
                    Button {
                        resultsObj.simulationRun.remove(at: i)
                        resultsObj.saveResults()
                        print("deleted")
                    } label: {
                        Text("Delete").tint(.red)
                    }

                }
                
            }
            .navigationBarTitle("Simulation Results!")

        }.onAppear(){
            resultsObj.loadResults()
        }
        
    }
}

//struct AllResults_Previews: PreviewProvider {
//    static var previews: some View {
////        AllResults( showView: .constant(false))
//    }
//}
