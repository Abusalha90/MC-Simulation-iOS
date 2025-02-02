//
//  NuclearEvent.swift
//  MonteCarloSimulation
//
//  Created by Mohammad Abusalha on 1/10/25.
//


import SwiftUI

struct NuclearEvent: Identifiable, Codable {
    let id = UUID()
    let year: Int
    let title: String
    let description: String
}

struct NuclearTimeline: Codable {
    let title: String?
    let description: String?
    let events: [NuclearEvent]
    
    init(title: String?, description: String?, events: [NuclearEvent]) {
        self.title = title
        self.description = description
        self.events = events
    }
}

struct NuclearTimelineView: View {
    @State private var sliderPosition: CGFloat = 0.0
    @State var timeLine: NuclearTimeline = .init(title: "Nuclear Timeline", description: "", events: [])
    @State private var selectedEventID: UUID? // Track the selected event
    
    var body: some View {
        VStack {
            Text(timeLine.title ?? "Nuclear Timeline")
                .font(.largeTitle)
                .bold()
            Text(timeLine.description ?? "")
                .font(.subheadline)
                .padding()
            ScrollViewReader { value in
                
                GeometryReader { geometry in
                    ScrollView {
                        ZStack(alignment: .leading) {
                            // Vertical Line
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 4)
                                .offset(x: 19, y: sliderPosition)
                            
                            VStack(alignment: .leading, spacing: 25) {
                                ForEach(timeLine.events) { event in
                                    EventRow(event: event, isSelected: selectedEventID == event.id)
                                        .id(event.id) // Assign an ID for scrollTo
                                    
                                        .onTapGesture {
                                            withAnimation {
                                                if selectedEventID == event.id {
                                                    selectedEventID = nil // Deselect
                                                } else {
                                                    selectedEventID = event.id // Select
                                                    value.scrollTo(event.id, anchor: .top)
                                                }
                                            }
                                            
                                        }
                                }
                            }
                            .background(GeometryReader {
                                Color.clear.preference(key: ViewOffsetKey.self,
                                                       value: -$0.frame(in: .named("scroll")).origin.y+200)
                            })
                            .onPreferenceChange(ViewOffsetKey.self) {geo in
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    // Update slider position when the event appears
                                    sliderPosition = geo
                                }
                            }
                            
                            .padding(.leading, 40)
                        }
                        .padding(.vertical)
                    }.coordinateSpace(name: "scroll")
                }
            }
            .onAppear {
                loadNuclearTimeline()
            }
        }
    }
    
    func loadNuclearTimeline() {
        guard let url = Bundle.main.url(forResource: "NuclearTimeline", withExtension: "json") else {
            print("JSON file not found")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let timeline = try JSONDecoder().decode(NuclearTimeline.self, from: data)
            self.timeLine = timeline
        } catch {
            print("Error loading or decoding JSON: \(error)")
        }
    }
}

struct EventRow: View {
    let event: NuclearEvent
    var isSelected: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Bullet Point
            Circle()
                .fill(Color.blue)
                .frame(width: 12, height: 12)
                .offset(x: -20)
            
            // Event Details
            VStack(alignment: .leading, spacing: 5) {
                Text(event.year.description)
                    .font(.headline)
                    .bold()
                Text(event.title)
                    .font(.title3)
                    .foregroundColor(.primary)
                Text(event.description)
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .background(isSelected ? Color.blue.opacity(0.3) : Color.clear) // Highlight when selected
        
    }
}

struct NuclearTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        NuclearTimelineView()
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
