//
//  SwiftUIView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 02/01/2023.
//

import SwiftUI

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        ParticleVisualization(object: Criticality_Sim())
    }
}

struct ParticleVisualization: View {
    let colors:[Color] = [.red, .green,.orange, .yellow]
    @ObservedObject var object : Criticality_Sim
    
    @State private var animate = false
    func getPath(scaleX:Double,scaleY:Double,origin:CGPoint) -> some View {
        Path { path in
            path.move(to: object.particleHistory.first!.r.position(aZ: scaleX, aY: scaleY,origin: origin))
                
            object.particleHistory.forEach { point in
                path.addLine(to: point.r.position(aZ: scaleX, aY: scaleY, origin: origin))
            }
        }
        .stroke(Color.black, lineWidth: 1.0)
    }
    let height = 1000.0
    var body: some View {
        VStack {
            HStack {
                Text("Reaction Speed")
                Spacer().frame(width: 40)
                Slider(value: $object.animatingSpeed,
                    in: 0.01...1.0,
                    step: 0.0001) {
                    Text("0.01")
                } minimumValueLabel: {
                    Image(systemName: "hare.fill")
                } maximumValueLabel: {
                    Image(systemName: "tortoise.fill")
                }
            }.padding()
                
            GeometryReader { geo in
                ScrollViewReader { view in
                    ScrollView(){
                      
                        ZStack {
                            VStack(spacing: 0) {
                                ForEach(0..<Int(height)) { i in
                                    Spacer().id(i).frame(height: Double(1))
                                    // for scroll view to the middle
                                }
                            }

                            HStack(spacing: 0) {
                                
                                ForEach($object.regionsView,id: \.id) { $region in
                                    
                                    Rectangle().foregroundColor(region.material == .Fuel ? .yellow:.blue)
                                        .border(.black)
                                        .frame(width:region.thickness*geo.size.width/object.rightBoundary)
                                }
                            }.frame(height: height)
                                
                            HStack{
                                Text("Z=0")
                                Rectangle()
    //                                .frame(minHeight: geo.size.height)
                                    .background(.red)
                                    .frame(height: 1)
                            }
                            getPath(scaleX: geo.size.width/object.rightBoundary, scaleY:geo.size.height/100, origin:  CGPoint(x: 0, y: height/2))
                            
                            ZStack{
                                Circle()
                                    .fill(colors[object.particle.g.rawValue])
                                if object.killParticle{
                                    Text("X")
                                }
                            }.frame(width: 20*(exp(object.particle.w)))
                                .position(object.particle.r.position(aZ: geo.size.width/object.rightBoundary,
                                                                     aY: geo.size.height/100, origin: CGPoint(x: 0, y: height/2)))
                                .animation(.spring(), value: object.animating)
                                .frame(minHeight: geo.size.height)

                            
                        }.onAppear(){
                            view.scrollTo(Int(height/3))
                        }

                    }
                    
                }
            }
            .clipped()
            HStack{
                Text("Energy Group").padding(.leading)
                ForEach(energyGroup.allCases,id:\.self) { g in
                    Circle()
                        .fill(colors[g.rawValue])
                        .frame(width: 10)
                    Text("G\(g.rawValue+1)")
                }
                Spacer()
                if object.animateRussianRollete {
                    RussianRoulette(shot: $object.killParticle).frame(width: 50)
                }
            }.frame(height: 50)
        }
    }
}


struct Line : Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 100, y: 100))
        return path
    }
}
