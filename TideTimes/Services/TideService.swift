import Foundation

class TideService: ObservableObject {
    private let apiKey = "YOUR_API_KEY" // Replace with your WorldTides API key
    private let baseURL = "https://www.worldtides.info/api/v2"
    
    @Published var tideData: [TideData] = []
    @Published var currentHeight: Double?
    @Published var error: Error?
    
    func fetchTideData(for location: Location) async {
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(byAdding: .hour, value: -12, to: now)!
        let endTime = calendar.date(byAdding: .hour, value: 12, to: now)!
        
        let urlString = "\(baseURL)/heights?lat=\(location.latitude)&lon=\(location.longitude)&start=\(Int(startTime.timeIntervalSince1970))&end=\(Int(endTime.timeIntervalSince1970))&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(TideResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.tideData = response.heights.map { height in
                    TideData(height: height.height,
                            time: Date(timeIntervalSince1970: TimeInterval(height.dt)),
                            type: self.determineTideType(height: height.height, heights: response.heights))
                }
                self.currentHeight = self.getCurrentHeight()
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
    
    private func determineTideType(height: Double, heights: [Height]) -> TideData.TideType {
        // Simple logic to determine if it's a high or low tide
        // In a real app, you'd want more sophisticated logic
        let index = heights.firstIndex { $0.height == height } ?? 0
        if index > 0 && index < heights.count - 1 {
            let prev = heights[index - 1].height
            let next = heights[index + 1].height
            return height > prev && height > next ? .high : .low
        }
        return .low
    }
    
    private func getCurrentHeight() -> Double? {
        let now = Date()
        return tideData.first { abs($0.time.timeIntervalSince(now)) < 300 }?.height
    }
}

// API Response Models
struct TideResponse: Codable {
    let heights: [Height]
}

struct Height: Codable {
    let dt: Int
    let height: Double
} 