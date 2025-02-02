//
//  RegionView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 22/12/2022.
//

import SwiftUI

struct RegionView: View {
    @ObservedObject var object: Criticality_Sim
    @Binding var region: Region
    @Binding var showView:Bool
    var saveFunc: (() -> Void)? = nil
    var deleteFunc: (() -> Void)? = nil

    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    var body: some View {
        
        VStack{
            HStack {
                Button {
                    showView.toggle()
                } label: {
                    Image(systemName: "chevron.backward").foregroundColor(.black)
                }
                Spacer()
                Text("Region \(region.id)").font(.title)
                Spacer()
                Button {
                    showView.toggle()
                    saveFunc?()
                } label: {
                    Text("Save")
                }
                
            }.padding()
            
            ScrollView{
                VStack{
                    HStack{
                        Text("Material Type ")
                        Picker(selection: $region.material, label: Text("Material Type")) {
                            ForEach(materialType.allCases, id: \.self) { value in
                                
                                Text(value.name)
                                    .tag(value)
                            }
                        }
                        .pickerStyle(.menu)
                    }.padding()
                    
                    HStack{
                        Text("Thickness ")
                        Spacer()
                        TextField("", value: $region.thickness,formatter: formatter )
                            .textFieldStyle(.roundedBorder).frame(width: 100)
                    }.padding()
                    
                    
                    Section("Cross Sections"){
                        ForEach($region.data , id: \.id) { data in
                            GroupBox("Group \(data.id + 1)"){
                                TextFieldView(value: data.total, label: "Total")
                                TextFieldView(value: data.absorb, label: "Absorbtion")
                                TextFieldView(value: data.scattGroup, label: "Group Scattering")
                                TextFieldView(value: data.v_fission, label: "v_Fission")
                                TextFieldView(value: data.v, label: "Fission Rate")
                                TextFieldView(value: data.X, label: "Fission spectrum")
                            }
                            Spacer().frame(height: 10)
                        }
                        
                    }
                }
            }
            
            Button {
                showView.toggle()
                deleteFunc?()
            } label: {
                Text("Delete Region")
            }
            Spacer().frame(height: 10)
        }
    }
}

//struct RegionView_Previews: PreviewProvider {
//
//    @State var ff = Region(id: 0, type: .Fuel, xLeft: 0.0, thickness: 0.0, data: [])
//
//    static var previews: some View {
//        RegionView(object: Criticality_Sim(), region: ff, showView: .constant(true))
//    }
//}


struct TextFieldView: View {
    @Binding var value:Double
    var label:String
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
        HStack{
            Text(label)
            Spacer()
            TextField("", value: $value,formatter: formatter )
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
        }.padding([.leading,.trailing],10)
    }
}



