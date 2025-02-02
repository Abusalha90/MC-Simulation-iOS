import SwiftUI
import Charts

struct view_Previes5gws: PreviewProvider {
    static var previews: some View {
        ContentView3()
    }
}
struct ContentView3: View {
    @State private var slabThickness: String = ""
    @State private var slabDensity: String = ""
    @State private var criticalityResult: String = "Not Calculated"
    @State private var isAnimationOn: Bool = true
    @State private var animationSpeed: Double = 1.0

    // Sample data for the chart
    let chartData: [DataPoint] = [
        DataPoint(x: 1, y: 20),
        DataPoint(x: 2, y: 25),
        DataPoint(x: 3, y: 15),
        DataPoint(x: 4, y: 30),
        DataPoint(x: 5, y: 35)
    ]

    var body: some View {
        ZStack {
            // Background Image
            Image("BackgroundPattern")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Header Section
                VStack(spacing: 10) {
                    Image(systemName: "atom")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color("PrimaryBlue"))
                    Text("Nuclear Criticality Calculator")
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color("PrimaryText"))
                    Text("Slab Reactor Geometry")
                        .font(.system(size: 18))
                        .foregroundColor(Color("SecondaryText"))
                }
                // Main Criticality Calculation Section
                VStack(spacing: 15) {
                    Text("Nuclear Criticality")
                        .font(.title)
                        .foregroundColor(.white)
                        .bold()
                    
                    // Central Animation Section
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 2)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 200)
                        ParticleAnimationView()
                            .frame(width: 180, height: 180)
                    }
                    
                    Text("Estimated Criticality: 2.36")
                        .font(.title2)
                        .foregroundColor(.green)
                        .padding(.top, 10)
                }
                VStack(spacing: 20) {
                    InputField(title: "Slab Thickness (cm):", placeholder: "Enter thickness", text: $slabThickness)
                    InputField(title: "Slab Density (g/cm³):", placeholder: "Enter density", text: $slabDensity)

                    Button(action: calculateCriticality) {
                        HStack {
                            Image(systemName: "calculator")
                                .foregroundColor(.white)
                            Text("Calculate Criticality")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("PrimaryBlue"))
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(BlurView(style: .systemMaterial))
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)

                // Result Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("Criticality Result")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                    }
                    Text(criticalityResult)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding()
                .background(BlurView(style: .systemMaterial))
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)

                // Chart Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Monte Carlo Particle Distribution")
                        .font(.headline)
                        .foregroundColor(Color("PrimaryText"))

                    Chart {
                        ForEach(chartData) { dataPoint in
                            LineMark(
                                x: .value("X", dataPoint.x),
                                y: .value("Y", dataPoint.y)
                            )
                            .foregroundStyle(Color.cyan)
                        }
                    }
                    .frame(height: 200)
                    .background(Color.black)
                    .cornerRadius(15)
                }
                .padding()
                .background(BlurView(style: .systemMaterial))
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)

                Spacer()
            }
            .padding(.horizontal)
        }
    }

    func calculateCriticality() {
        guard let thickness = Double(slabThickness), let density = Double(slabDensity) else {
            criticalityResult = "Invalid Input"
            return
        }
        criticalityResult = String(format: "%.2f", thickness * density * 0.1) // Example formula
    }
}

struct DataPoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
}

struct InputField: View {
    var title: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color("PrimaryText"))
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}


// Custom Particle Animation View
struct ParticleAnimationView: View {
    @State private var particles = Array(repeating: CGSize.zero, count: 30)
    
    var body: some View {
        ZStack {
            ForEach(particles.indices, id: \.self) { index in
                Circle()
                    .fill(Color.random)
                    .frame(width: 8, height: 8)
                    .offset(x: particles[index].width, y: particles[index].height)
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: Double.random(in: 1.5...3.0))
                                .repeatForever(autoreverses: true)
                        ) {
                            particles[index] = CGSize(
                                width: CGFloat.random(in: -100...100),
                                height: CGFloat.random(in: -100...100)
                            )
                        }
                    }
            }
        }
    }
}

