//
//  ContentView 2.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/10/25.
//

import SwiftUI
import RealityKit
import Combine
import SwiftUIJoystick
import ARKit


#Preview {
    NavigationStack {
        
        
        Nuclear3DView()
    }
}

class AnchorManager: ObservableObject {
    @Published var anchorEntity: AnchorEntity?
}

struct Nuclear3DView: View {
    let modelNames = ["NPP_poly", "Chernobyl_NPP", "PWR"]
    let names = ["Nuclear Powerplant", "Chernobyl NPP", "PWR"]
    @State private var selectedModelIndex = 0
    @State private var resetPosition = false
    
    @StateObject private var anchorManager = AnchorManager()
    @StateObject var leftStick: JoystickMonitor = JoystickMonitor()
    @StateObject var rightStick: JoystickMonitor = JoystickMonitor()

    @State var showJoysticks: Bool = true
    @State var showControls: Bool = false
    
    @State var manualControlEnabled: Bool = true // ✅ New toggle for manual movement

    // ✅ Persistent ARView instance (Prevents recreation)
    private static var sharedARView: ARView = {
        let view = ARView(frame: .zero)
        return view
    }()

    var body: some View {
        ZStack {
            ARViewContainer2(
                modelName: modelNames[selectedModelIndex],
                resetPosition: $resetPosition,
                anchorManager: anchorManager,
                arView: Self.sharedARView,
                leftStick: leftStick,
                rightStick: rightStick,
                manualControlEnabled: $manualControlEnabled
            )
            .edgesIgnoringSafeArea(.all)
            
            if showJoysticks {
                MyJoystickView(leftStick: leftStick, rightStick: rightStick)
            }
            
            if showControls {
                VStack {
                    Toggle(isOn: $showJoysticks) {
                        Text("Use manual Sticks")
                            .foregroundStyle(Color.accentRadiation)
                    }
                    .padding()
                    .onChange(of: showJoysticks) { newValue in
                        manualControlEnabled = newValue // ✅ Enable manual control when joysticks are shown
                    }
                    Picker("Select Model", selection: $selectedModelIndex) {
                        ForEach(modelNames.indices, id: \.self) { index in
                            Text(modelNames[index])
                                .frame(width: 70, height: 70)
                                .tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .background(Color.secondaryColor)
                    .cornerRadius(5)
                    .padding()
                    
                    Button(action: {
                        resetPosition.toggle()
                    }) {
                        Text("Reset Position")
                            .font(.headline)
                            .foregroundColor(Color.accentRadiation)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(gradient: Gradient.appGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                    .cornerRadius(15)
                            )
                            .cornerRadius(10)
                            .padding()
                    }
                    .padding()
                }
                .background(Color.secondaryColor.opacity(0.5))
                .cornerRadius(20)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showControls.toggle()
                }) {
                    Image(systemName: "gear.circle")
                        .foregroundStyle(Color.accentRadiation)
                }
            }
        }
    }
}

struct ARViewContainer2: UIViewRepresentable {
    let modelName: String
    @Binding var resetPosition: Bool
    @ObservedObject var anchorManager: AnchorManager
    var arView: ARView // ✅ Use the shared ARView
    @ObservedObject var leftStick: JoystickMonitor
    @ObservedObject var rightStick: JoystickMonitor
    @Binding var manualControlEnabled: Bool // ✅ New binding

    
    func makeUIView(context: Context) -> ARView {
        if arView.scene.anchors.isEmpty {
            setupARView(arView, context: context)
        }
        return arView
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(arView: arView, leftStick: leftStick, rightStick: rightStick, manualControlEnabled: $manualControlEnabled) // ✅ Pass toggle to Coordinator
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if resetPosition {
            DispatchQueue.main.async {
                resetPosition = false
                if let camera = uiView.scene.findEntity(named: "camera") {
                    camera.transform.translation = [0, 0, -2]
                    camera.transform.rotation = simd_quatf(angle: 0, axis: [0, 1, 0]) // Reset rotation
                }
            }
        }
    }
    
    private func setupARView(_ arView: ARView, context: Context) {
        print("Setting up ARView with device motion")

        // Remove old anchors to prevent duplication
        arView.scene.anchors.removeAll()

        // Create an anchor for the 3D model
        let objectAnchor = AnchorEntity(world: [0, 0, 0])
//        objectAnchor.orientation = simd_quatf(angle: .pi / 2 , axis: [0, 1, 0]) // Rotate object anchor instead

        do {
            let modelEntity = try ModelEntity.load(named: modelName + ".usdz")
            modelEntity.generateCollisionShapes(recursive: true)
            modelEntity.scale = SIMD3<Float>(2, 2, 2) // Scale down if the model is too large
            objectAnchor.addChild(modelEntity)
        } catch {
            print("Error loading model: \(error.localizedDescription)")
        }

        // Add the model anchor to the scene
        arView.scene.addAnchor(objectAnchor)

        // Enable device motion for camera orientation
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading // Align with real-world gravity and heading
        configuration.isAutoFocusEnabled = true
        arView.session.run(configuration)

        // Add a camera entity
        let cameraAnchor = AnchorEntity(world: .zero)
        let cameraEntity = PerspectiveCamera()
        cameraEntity.name = "camera"
        cameraEntity.position = [0, 0, 0] // Start 5 meters behind the object

        // Adjust the camera's initial rotation to align with the object
//        let rotation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0]) // Rotate 90 degrees around the Y-axis
//        cameraEntity.transform.rotation = rotation

        cameraAnchor.addChild(cameraEntity)
        arView.scene.addAnchor(cameraAnchor)

        // Start updating camera rotation
        context.coordinator.setupCameraRotationUpdates()
        context.coordinator.setupJoystickMovement()
        
        // Debug: Print camera initial position and rotation
        print("Initial Camera Position: \(cameraEntity.position)")
        print("Initial Camera Rotation: \(cameraEntity.orientation)")
    }

    // Coordinator for handling joystick inputs
    class Coordinator: NSObject {
        var cancellables = Set<AnyCancellable>()
        var arView: ARView
        @ObservedObject var leftStick: JoystickMonitor
        @ObservedObject var rightStick: JoystickMonitor
        @Binding var manualControlEnabled: Bool

        init(arView: ARView, leftStick: JoystickMonitor, rightStick: JoystickMonitor, manualControlEnabled: Binding<Bool>) {
            self.arView = arView
            self.leftStick = leftStick
            self.rightStick = rightStick
            self._manualControlEnabled = manualControlEnabled
        }

        func setupJoystickMovement() {
            leftStick.$xyPoint
                .combineLatest(rightStick.$xyPoint)
                .receive(on: DispatchQueue.main)
                .throttle(for: .milliseconds(50), scheduler: RunLoop.main, latest: true)
                .sink { [weak self] leftXY, rightXY in
                    guard let self = self else { return }
                    if self.manualControlEnabled {
                        self.updateCameraMovement(leftXY: leftXY, rightXY: rightXY)
                    }
                }
                .store(in: &cancellables)
        }

        func setupCameraRotationUpdates() {
            // Update camera rotation every frame
            arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
                guard let self = self else { return }
                self.updateCameraRotation()
            }.store(in: &cancellables)
        }
        
        func updateCameraRotation() {
            guard let camera = arView.scene.findEntity(named: "camera") else {
                print("❌ Camera entity not found!")
                return
            }

            // Get the current AR frame
//            if let currentFrame = arView.session.currentFrame {
//                // Use the device's orientation to update the camera's rotation
//                let deviceOrientation = currentFrame.camera.transform
//                camera.transform.rotation = simd_quatf(deviceOrientation)
//            }
            if let currentFrame = arView.session.currentFrame {
                let arKitTransform = currentFrame.camera.transform

                // ✅ Extract only the rotation component from the ARKit transform
                let arKitRotation = simd_quaternion(arKitTransform)

                // ✅ Apply a correction transformation to match RealityKit’s coordinate system
                let correctionRotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0]) // Rotate -90° around X-axis

                // ✅ Apply the corrected rotation
                camera.transform.rotation = correctionRotation * arKitRotation
                print("Camera Rotation (Quaternion): \(camera.transform.rotation)")

            }
        }

        
        func updateCameraMovement(leftXY: CGPoint, rightXY: CGPoint) {
            guard let camera = arView.scene.findEntity(named: "camera") else {
                print("❌ Camera entity not found!")
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                let movementSpeed: Float = 0.05
                let rotationSpeed: Float = 0.001

                // ✅ Movement
                let moveX = Float(rightXY.x) * movementSpeed // Right stick moves X direction
                let moveY = Float(rightXY.y) * movementSpeed * -1 // Right stick moves Y direction
                let moveZ = Float(leftXY.y) * movementSpeed  // Left stick moves Z direction
                let rotateZAxis = Float(leftXY.x) * rotationSpeed  // Left stick moves Z direction
                let rotationZ = simd_quatf(angle: rotateZAxis, axis: [0, 1, 0])

                camera.position.x += moveX
                camera.position.y += moveY
                camera.position.z += moveZ
                // Rotation
//                let rotateX = Float(leftXY.x) * rotationSpeed
//                let rotateY = Float(rightXY.x) * rotationSpeed
//
//                let rotationX = simd_quatf(angle: rotateX, axis: [0, 1, 0])
//                let rotationY = simd_quatf(angle: rotateY, axis: [1, 0, 0])

//                camera.transform.rotation = rotationZ * camera.transform.rotation

                print("📍 Camera Position: \(camera.position)") // Debugging output
                print("📍 Camera Rotation: \(camera.transform.rotation)")

            }
        }

        @objc func handleTap(gesture: UITapGestureRecognizer) {
            let tapLocation = gesture.location(in: arView)
            if let tappedEntity = arView.entity(at: tapLocation) as? ModelEntity {
                teleport(to: tappedEntity)
            }
        }
        
        func teleport(to entity: ModelEntity) {
            if let camera = arView.scene.findEntity(named: "camera") {
                let targetPosition = entity.transform.translation
                let originalPosition = camera.transform.translation

                // Animate the camera movement
                let animationDuration: Float = 0.5
                var timeElapsed: Float = 0

                Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                    timeElapsed += 0.01
                    let t = min(timeElapsed / animationDuration, 1.0) // Normalize time to [0, 1]

                    // Interpolate the position
                    camera.transform.translation = SIMD3<Float>(
                        x: originalPosition.x + t * (targetPosition.x - originalPosition.x),
                        y: originalPosition.y + t * (targetPosition.y - originalPosition.y),
                        z: originalPosition.z + t * (targetPosition.z - originalPosition.z)
                    )

                    if t >= 1.0 {
                        timer.invalidate() // Stop the animation when complete
                    }
                }
            }
        }
//
//        @objc func handlePinch(gesture: UIPinchGestureRecognizer) {
//            guard let modelEntity = anchorEntity?.children.first as? ModelEntity else { return }
//            switch gesture.state {
//            case .changed:
//                modelEntity.scale *= Float(gesture.scale)
//                gesture.scale = 1
//            default:
//                break
//            }
//        }
//        
//        @objc func handleRotation(gesture: UIRotationGestureRecognizer) {
//            guard let modelEntity = anchorEntity?.children.first as? ModelEntity else { return }
//            
//            switch gesture.state {
//            case .changed:
//                modelEntity.orientation *= simd_quatf(angle: Float(gesture.rotation), axis: [0, 1, 0])
//                gesture.rotation = 0
//            default:
//                break
//            }
//        }
//        
//        @objc func handlePan(gesture: UIPanGestureRecognizer) {
//            guard let modelEntity = anchorEntity?.children.first as? ModelEntity else { return }
//            
//            let translation = gesture.translation(in: gesture.view)
//            let xTranslation = Float(translation.x / 1000)
//            let yTranslation = Float(-translation.y / 1000)
//            
//            modelEntity.position.x += xTranslation
//            modelEntity.position.y += yTranslation
//            
//            gesture.setTranslation(.zero, in: gesture.view)
//        }
    }
}
