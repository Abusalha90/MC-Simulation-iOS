//
//  RussianRoulette.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 09/01/2023.
//

import SwiftUI
struct CircleShape:Shape{
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
//        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control1: CGPoint(x: rect.midX, y: rect.midY), control2: CGPoint(x: rect.maxX, y: rect.maxY))
//        path.addCurve(to: CGPoint(x: rect.minX, y: rect.minY), control1: CGPoint(x: rect.maxX, y: rect.minY), control2: CGPoint(x: rect.minX, y: rect.maxY))

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

struct Arc:Shape{
    let startAngle:Angle
    let endAngle:Angle
    let clockWise:Bool
    func point(center:CGPoint,r:Double,theta:Double)->CGPoint{
        let x = r*theta.cosin + center.x
        let y = r*theta.sinus + center.y
        
        return CGPoint(x: x, y: y)
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = rect.width
        let center = CGPoint(x: rect.midX, y: rect.midY)
        for i in Array(0..<6){
            let phi1 = startAngle + .degrees(Double(60*i))
            let phi2 = endAngle + .degrees(Double(60*i))
            path.addArc(center: center, radius: r, startAngle:phi1, endAngle:phi2, clockwise: clockWise)
            path.addQuadCurve(to: point(center: center, r: r, theta: phi2.degrees + Double(20)), control: point(center: center, r: r*9/12, theta: Double(90 + 60*i)))
        }

        return path
    }
}
struct RussianRoulette: View {
    
    @State var rotateFactor: CGFloat = 1.0
    @State var sec: Double = 2.9
    @State var animationSpeed: Double = 1.0
    
    // Constants for reuse
    private let arcAngle: Double = 60.0
    private let rotateSpeed: Double = 100.0

    @Binding var shot:Bool
    var body: some View {
        GeometryReader{ geo in
            HStack{
                Spacer()
                ZStack {
                    Arc(startAngle: .degrees(40), endAngle: .degrees(80), clockWise: false)
                        .fill(.gray)
                        .frame(width: geo.size.width/2)

                    Circle()
                        .stroke(.black,lineWidth: 10)
                        .frame(width: geo.size.width/4)
                    Circle()
                        .fill(.black)
                        .frame(width: geo.size.width/7)

                    ForEach(0..<6) { i in
                        ZStack {
                            Circle()
                                .fill((i == 0 && !shot) ? .yellow : .black)
                                .frame(width: geo.size.width/5)
                                .offset(x: geo.size.width/3)
                                .rotationEffect(Angle.degrees(arcAngle * Double(i)))

                            if i == 0, !shot {
                                Circle()
                                    .fill(.gray)
                                    .frame(width: geo.size.width/10)
                                    .offset(x: geo.size.width/3)
                                    .rotationEffect(Angle.degrees(arcAngle * Double(i)))
                            }
                        }
                    }
                }.rotationEffect(Angle.degrees(rotateSpeed*rotateFactor))
            
                Spacer()
            }
                .animation(.easeIn(duration: sec*animationSpeed), value: rotateFactor)

            }
                .onAppear(){
                    rotateFactor += 10
                }
        
        
      

    }
}
struct BulletShellBackView: View {
    var body: some View {
        ZStack {

            // Casing rim (inner part of the casing)
            Circle()
                .stroke(Color.black, lineWidth: 4) // Adds a black stroke around the rim
                .frame(width: 60, height: 60)
                .offset(y: -30) // Position the circle at the top of the casing
            
            // Bullet casing bottom (indented part of the casing)
            Circle()
                .fill(Color.gray)
                .frame(width: 50, height: 50) // Indentation is smaller
                .offset(y: 30) // Position it to the bottom of the casing
            
            // Bullet casing bottom center (small circle to represent the primer)
            Circle()
                .fill(Color.black)
                .frame(width: 15, height: 15)
                .offset(y: 30) // Centered on the bottom of the casing
        }
        .rotationEffect(Angle(degrees: 0)) // Optionally adjust the rotation if needed
    }
}
struct RussianRoulette_Previews: PreviewProvider {
    static var previews: some View {
        BulletShellBackView()

    }
}
