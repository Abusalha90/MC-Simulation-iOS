//
//  ParticleCollisionView.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/10/25.
//


import SwiftUI
import RealityKit
import ARKit
import Combine


struct ParticleCollisionView: View {
    @State private var isARSessionRunning = true

    var body: some View {
        VStack {
            ARViewContainer(isARSessionRunning: $isARSessionRunning)
                .edgesIgnoringSafeArea(.all)
            
            Toggle(isOn: $isARSessionRunning) {
                Text("Pause/Resume AR Session")
            }
            .padding()
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    // Subscriptions must be stored to avoid being deallocated
    let handler = ParticleCollisionHandler()

    // Binding to control whether the AR session is running or paused
    @Binding var isARSessionRunning: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Create an anchor for the particles
        let anchorEntity = AnchorEntity(world: [0, 0, 0])
        arView.scene.addAnchor(anchorEntity)

        let particle = createParticle(color: .random)
        
        // Set initial position for the particle
        particle.position = [0, 0, -1]
        anchorEntity.addChild(particle)
        handler.addParticle(particle)
        startARSession(in: arView)

        return arView
    }
    

    func updateUIView(_ uiView: ARView, context: Context) {
        if !isARSessionRunning {
            uiView.session.pause()  // Pause the session if state is off
        } else {
            if uiView.session.currentFrame == nil {
                startARSession(in: uiView)  // Restart the session if state is on
            }
        }
    }
    
    // Function to create a particle (simple sphere entity)
    func createParticle(color: Color) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.05)
        
        // Convert SwiftUI Color to UIColor
        let uiColor = UIColor(color)
        let material = SimpleMaterial(color: uiColor, isMetallic: false)
        
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        return modelEntity
    }

    // Function to start the AR session
    func startARSession(in arView: ARView) {
        if ARWorldTrackingConfiguration.isSupported {
            let configuration = ARWorldTrackingConfiguration()
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
    }

    // Function to pause the AR session when view is removed
    static func dismantleUIView(_ uiView: ARView, coordinator: ()) {
        uiView.session.pause()  // Pause the AR session explicitly
    }
}

class ParticleCollisionHandler {
    // Store the subscriptions as a class property
    var subscriptions = Set<AnyCancellable>()
    var particles: [AirResistanceParticle] = []
    let dragCoefficient: Float = 0.47 // Drag coefficient for spherical particles
    let airDensity: Float = 1.225 // Air density in kg/m^3
    let particleRadius: Float = 0.05 // Particle radius in meters

    
    func setUpCollisionDetection(for arView: ARView, particle1: ModelEntity, particle2: ModelEntity) {
        // Ensure both particles have collision components
        particle1.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.05)])
        particle2.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.05)])

        // Add both entities to the scene or anchor
        arView.scene.anchors.first?.addChild(particle1)
        arView.scene.anchors.first?.addChild(particle2)

        // Subscribe to collision events
        arView.scene.subscribe(to: CollisionEvents.Began.self) { event in
            if (event.entityA == particle1 && event.entityB == particle2) ||
               (event.entityA == particle2 && event.entityB == particle1) {
                // Handle collision (e.g., change color or stop particles)
                particle1.model?.materials = [SimpleMaterial(color: .green, isMetallic: false)]
                particle2.model?.materials = [SimpleMaterial(color: .green, isMetallic: false)]
                print("Collision detected between particles!")
                self.updateSimulation()

            }
        }.store(in: &subscriptions)
    }
    
    
    // Method to add a particle to the simulation
    func addParticle(_ entity: ModelEntity) {
        let initialVelocity = SIMD3<Float>(0, 0, 0) // Initial velocity of the particle
        let particle = AirResistanceParticle(entity: entity, velocity: initialVelocity)
        particles.append(particle)
    }
    
    // Method to simulate air resistance (drag force)
    func applyAirResistance() {
        for i in 0..<particles.count {
            var particle = particles[i]
            
            // Calculate the drag force
            let velocityMagnitude = length(particle.velocity)
            if velocityMagnitude > 0 {
                // Drag force: F = 0.5 * Cd * A * ρ * v^2
                let crossSectionalArea: Float = .pi * pow(particleRadius, 2)
                let dragForce = -0.5 * dragCoefficient * airDensity * crossSectionalArea * pow(velocityMagnitude, 2)
                
                // Apply drag force by reducing the particle's velocity
                let dragAcceleration = dragForce / particle.entity.physicsBody!.massProperties.mass
                particle.velocity += dragAcceleration * 0.016 // Simulate the effect over time (assuming 60 FPS)

                // Update the particle's position based on the new velocity
                particle.entity.position += particle.velocity * 0.016
            }
            
            // Update the particle in the simulation list
            particles[i] = particle
        }
    }
    
    // Method to update the simulation every frame
    func updateSimulation() {
        applyAirResistance() // Apply air resistance for all particles
    }
    
}

// The AirResistanceParticle struct will store the particle's position and velocity
struct AirResistanceParticle {
    var entity: ModelEntity
    var velocity: SIMD3<Float>
}
