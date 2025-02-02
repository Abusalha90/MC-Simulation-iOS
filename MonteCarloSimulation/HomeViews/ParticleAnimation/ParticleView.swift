//
//  ParticleView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/8/25.
//

import SwiftUI


struct ParticleView_Previews: PreviewProvider {
    static var previews: some View {
        ParticleView(animationSpeed: .constant(2), gridSize: .constant(300), particleCount: .constant(150))
    }
}

struct ParticleView: View {
    @State private var particles: [Particle] = []
    @State private var timer: Timer? = nil  // Store the timer
    @State private var resetTimer: Bool = false // Flag to reset animation
    @Binding var animationSpeed: Double

    @Binding var gridSize: CGFloat
    @Binding var particleCount: Int

    let innerColors: [Color] = [.orange, .brown]
    let outerColors: [Color] = [.white, .blue]
    var radius: CGFloat {
        gridSize/2
    }
    var nucleusCenter : CGPoint {
        CGPoint(x: radius, y: radius)
    }
    
    var body: some View {
        ZStack {
            // Circular Grid
            Circle()
                .stroke(lineWidth: 5)
                .foregroundColor(Color.accentRadiation.opacity(0.3))
                .frame(width: gridSize, height: gridSize)
                .overlay(
                    ForEach(1..<10) { i in
                        Circle()
                            .stroke(lineWidth: 1)
                            .foregroundColor(Color.accentRadiation.opacity(0.2))
                            .frame(width: CGFloat(i) * (gridSize / 10), height: CGFloat(i) * (gridSize / 10))
                    }
                )
            
            // Radial Lines
            ForEach(0..<360, id: \.self) { angle in
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1, height: gridSize / 2)
                    .offset(y: -(gridSize / 4))
                    .rotationEffect(.degrees(Double(angle)))
            }
            
            ForEach(particles) { particle in
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: particle.isOuter ? outerColors : innerColors),
                            center: .center,
                            startRadius: 0,
                            endRadius: 6
                        )
                    )
                    .frame(width: particle.isOuter ? 12 : 6, height: particle.isOuter ? 12 : 6)
                    .position(particle.position1)
                    .opacity(particle.isOuter ? 1.0 : 0.9)
                    .shadow(
                        color: particle.isOuter ? particle.color.opacity(0.8) : .clear,
                        radius: particle.isOuter ? 8 : 0,
                        x: 0, y: 0
                    )
                    .shadow(
                        color: particle.isOuter ? particle.color.opacity(0.8) : .clear,
                        radius: particle.isOuter ? 12 : 0,
                        x: 0, y: 0
                    )
                    .overlay(
                        LineEffect(from: nucleusCenter,
                                   to: particle.position1,
                                   animationSpeed: $animationSpeed)
                    )
                    
            }
            .frame(width: gridSize, height: gridSize)
           
        }
        .onAppear {
            animateParticles()
        }
        .onChange(of: gridSize) { _,_ in
            generateParticles()
        }
    }
    
    func generateParticles() {
        particles = (0..<particleCount).map { _ in
            let angle = CGFloat.random(in: 0...2 * .pi)
            let position1 = nucleusCenter
            let radiusOffset = CGFloat.random(in: 0...radius)
            let position2 = CGPoint(
                x: radius + radiusOffset * cos(angle),
                y: radius + radiusOffset * sin(angle)
            )
            let isOuter = radiusOffset > radius * 0.7
            let color = isOuter ? outerColors.randomElement() ?? .white : innerColors.randomElement() ?? .orange
            
            return Particle(position1: position1,
                            position2: position2,
                            radius: radius,
                            angle: angle,
                            color: color,
                            isOuter: isOuter)
        }
    }
    
    func animateParticles() {
        timer?.invalidate()

        if resetTimer {
            resetParticles()
        }

        timer = Timer.scheduledTimer(withTimeInterval: animationSpeed,
                                     repeats: true) { _ in
            generateParticles()
            let baseAnimation = Animation.easeInOut(duration: animationSpeed / 2)
            let repeated = baseAnimation.repeatForever(autoreverses: true)
            
            withAnimation(repeated) {
                particles = particles.map { particle in
                    var updatedParticle = particle
                    
                    if particle.radius != radius {
                        updatedParticle.position1 = nucleusCenter
                    } else {
                        updatedParticle.position1 = updatedParticle.position2
                    }
                    return updatedParticle
                }
            }
        }
    }

    func resetAnimation() {
        resetTimer = true
        animateParticles()
        resetTimer = false
    }

    func resetParticles() {
        particles = particles.map { particle in
            var updatedParticle = particle
            updatedParticle.position1 = nucleusCenter
            return updatedParticle
        }
    }
}

struct LineEffect: View {
    var from: CGPoint
    var to: CGPoint
    @Binding var animationSpeed : Double
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .trim(from: 0.0,
              to: from == to ? 0.0 : 0.7)
        .stroke(style: StrokeStyle(lineWidth: 1, lineCap: .round))
        .foregroundColor(.orange)
        .opacity(0.5)
        .animation(.easeInOut(duration: animationSpeed), value: from)
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position1: CGPoint
    var position2: CGPoint
    var radius: Double
    var angle: Double
    var color: Color
    var isOuter: Bool // Whether the particle belongs to the outer circle
}
