import Foundation

struct TideData: Codable, Identifiable {
    let id = UUID()
    let height: Double
    let time: Date
    let type: TideType
    
    enum TideType: String, Codable {
        case high = "High"
        case low = "Low"
    }
}

struct Location: Codable, Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
} 