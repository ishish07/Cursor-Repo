import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var tideService = TideService()
    @State private var searchText = ""
    @State private var selectedLocation: Location?
    @AppStorage("savedLocation") private var savedLocationData: Data?
    
    var body: some View {
        NavigationView {
            VStack {
                if let location = selectedLocation {
                    LocationHeader(location: location)
                    
                    if !tideService.tideData.isEmpty {
                        TideGraphView(tideData: tideService.tideData,
                                    currentHeight: tideService.currentHeight)
                            .frame(height: 300)
                            .padding()
                    } else {
                        ProgressView()
                    }
                } else {
                    LocationSearchView(searchText: $searchText,
                                     onLocationSelected: { location in
                        selectedLocation = location
                        saveLocation(location)
                        Task {
                            await tideService.fetchTideData(for: location)
                        }
                    })
                }
            }
            .navigationTitle("Tide Times")
            .onAppear {
                loadSavedLocation()
            }
        }
    }
    
    private func saveLocation(_ location: Location) {
        if let encoded = try? JSONEncoder().encode(location) {
            savedLocationData = encoded
        }
    }
    
    private func loadSavedLocation() {
        guard let data = savedLocationData,
              let location = try? JSONDecoder().decode(Location.self, from: data) else {
            return
        }
        selectedLocation = location
        Task {
            await tideService.fetchTideData(for: location)
        }
    }
}

struct LocationHeader: View {
    let location: Location
    
    var body: some View {
        Text(location.name)
            .font(.title2)
            .padding()
    }
}

struct TideGraphView: View {
    let tideData: [TideData]
    let currentHeight: Double?
    
    var body: some View {
        Chart {
            ForEach(tideData) { tide in
                LineMark(
                    x: .value("Time", tide.time),
                    y: .value("Height", tide.height)
                )
                .foregroundStyle(.blue)
                
                if tide.type == .high || tide.type == .low {
                    PointMark(
                        x: .value("Time", tide.time),
                        y: .value("Height", tide.height)
                    )
                    .foregroundStyle(tide.type == .high ? .red : .green)
                }
            }
            
            if let currentHeight = currentHeight {
                RuleMark(y: .value("Current", currentHeight))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
    }
}

struct LocationSearchView: View {
    @Binding var searchText: String
    let onLocationSelected: (Location) -> Void
    
    var body: some View {
        VStack {
            TextField("Search location...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // In a real app, you would implement location search here
            // For now, we'll show a sample location
            Button("Use Sample Location") {
                let sampleLocation = Location(
                    name: "San Francisco",
                    latitude: 37.7749,
                    longitude: -122.4194
                )
                onLocationSelected(sampleLocation)
            }
            .padding()
        }
    }
}