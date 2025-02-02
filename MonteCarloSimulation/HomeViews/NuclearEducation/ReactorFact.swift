//
//  ReactorFact.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/10/25.
//


import SwiftUI

struct ReactorFact: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageUrl: String // Use a URL string for remote or local images
}

struct NuclearFactCardView: View {
    @State private var currentFactIndex: Int = 0

    let facts: [ReactorFact] = [
        ReactorFact(
            title: "First Nuclear Reactor",
            description: "The first artificial nuclear reactor, Chicago Pile-1, was built in 1942 under the University of Chicago football field stands.",
            imageUrl: ""
        ),
        ReactorFact(
            title: "Largest Nuclear Power Plant",
            description: "Kashiwazaki-Kariwa in Japan is the largest nuclear power plant in the world by capacity.",
            imageUrl: "invalid_url" // Simulates an unavailable image
        ),
        ReactorFact(
            title: "Interesting Fact",
            description: "This is a much longer description that spans multiple lines to demonstrate the dynamic height adjustment of the card. The card should grow to fit this text comfortably without clipping.",
            imageUrl: "https://s3-ap-south-1.amazonaws.com/ricedigitals3bucket/AUPortalContent/2020/07/24010954/nuclear-physics.jpg"
        )
    ]

    var body: some View {
        VStack {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(LinearGradient(
                        gradient: Gradient.appGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(radius: 10)

                VStack(spacing: 15) {
                    // Conditionally display the image
                    AsyncImage(url: URL(string: facts[currentFactIndex].imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            // Placeholder while loading
                            ProgressView()
                                .frame(height: 120)
                        case .success(let image):
                            // Image loaded successfully
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        case .failure:
                            // Failed to load the image
                            EmptyView()
                        @unknown default:
                            EmptyView()
                        }
                    }

                    Text(facts[currentFactIndex].title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(facts[currentFactIndex].description)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
            .padding()
            .frame(maxWidth: .infinity) // Allow the card to take up full width
            .overlay(
                GeometryReader { geometry in
                    Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
                }
            )

            Button(action: {
                withAnimation {
                    currentFactIndex = (currentFactIndex + 1) % facts.count
                }
            }) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title)
                        .foregroundColor(Color.primaryForeground)
                    Text("Next Fact")
                        .font(.headline)
                        .foregroundColor(Color.primaryForeground)
                }
                .padding()
                .background(Color.primaryColor)
                .cornerRadius(15)
            }

            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct NuclearFactCardView_Previews: PreviewProvider {
    static var previews: some View {
        NuclearFactCardView()
    }
}
