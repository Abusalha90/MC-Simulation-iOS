//
//  GeometryView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 23/12/2022.
//

import SwiftUI

struct GeometryView: View {
    @ObservedObject var object : Criticality_Sim
    @State var presentView:Bool = false
    @State var selectedRegion:Region = Region(id: 0, type: .Fuel, xLeft: 0.0, thickness: 0.0, data: [])

    @State var editMode: editMode = .add
    
    var body: some View {
        VStack(spacing: 0){
            ScrollView(.horizontal) {
                
                HStack(spacing: 0) {
                    
                    ForEach($object.regionsView,id: \.id) { $region in
                        ZStack {
                            Rectangle().foregroundColor(region.type == .Fuel ? .yellow:.blue)
                                .border(selectedRegion.id == region.id ? .green:.black)
                                .frame(width:region.thickness*3)
                            
                                .onTapGesture {
                                    selectedRegion = region
                                }
                                .onLongPressGesture {
                                    selectedRegion = region
                                    editMode = .update
                                    presentView.toggle()
                                }
                            
                            Text(region.id.description)
                                .font(.system(size: 10))
                                
                        }
                    }
                    Spacer().frame(width: 10)
                    ZStack {
                        Circle().foregroundColor(.green)
                            .frame(width:30)
                        Text("+")
                    }
                    .onTapGesture {
                        print("Add slab")
                        
                        selectedRegion = Region(id: (object.regions.last?.id ?? 0) + 1, type: .Fuel, xLeft: object.rightBoundary, thickness: 10, data: [Xs.init()])
                        editMode = .add
                        presentView.toggle()
                    }
                    .fullScreenCover(isPresented: $presentView) {
                        
                        RegionView(object: object, region: $selectedRegion, showView: $presentView, saveFunc:{
                            
                            object.updateRegion(region: selectedRegion,mode:editMode)
                        }, deleteFunc: {
                            object.removeRegion(region: selectedRegion)
                        })
                    }
                    
                    
                    
                }.frame(height: 200)
                Text("Slab Width = "+(object.regions.map({$0.thickness}).reduce(0,+)).description + " cm")
                    .font(.system(size: 10))
                
            }
        }
    }
}

struct GeometryView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryView(object: Criticality_Sim())
    }
}
