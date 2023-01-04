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
    func getPath(aX:Double,bY:Double) -> some View {
        Path { path in
            path.move(to: object.particleHistory.first!.r.position(
                aZ: aX,
                aY: bY
            ))
                
            object.particleHistory.forEach { point in
                path.addLine(to: point.r.position(
                    aZ: aX,
                    aY: bY
                ))
            }
        }
        .stroke(Color.black, lineWidth: 1.0)
    }
    
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
                    Text("Fast")
                } maximumValueLabel: {
                    Text("Slow")
                }
            }.padding()
                
            GeometryReader { geo in
                ZStack {
                    HStack(spacing: 0) {
                        
                        ForEach($object.regionsView,id: \.id) { $region in
                            
                            Rectangle().foregroundColor(region.type == .Fuel ? .yellow:.blue)
                                .border(.black)
                                .frame(width:region.thickness*4)
                        }
                    }
                    getPath(aX: geo.size.width/object.rightBoundary, bY: geo.size.height/100)

                    Circle()
                        .fill(colors[object.particle.g.rawValue])
                        .frame(width: 20*(exp(object.particle.w)))
                        .position(CGPoint(
                            x:object.particle.r.z*geo.size.width/object.rightBoundary,
                            y:object.particle.r.y*geo.size.height/100))
                        .animation(.spring(), value: object.animating)
                }
            }
            .clipped()
            HStack{
                Text("Energy Group")
                ForEach(energyGroup.allCases,id:\.self) { g in
                    Circle()
                        .fill(colors[g.rawValue])
                        .frame(width: 10)
                    Text("G\(g.rawValue+1)")
                }
            }
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
