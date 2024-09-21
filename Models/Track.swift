import Foundation

struct Track: Identifiable, Codable {
    let id: UUID = UUID() // Automatisch generierte UUID
    var title: String
    var trackNumber: String
    
    var formattedTrackNumber: String {
        if let number = Int(trackNumber) {
            return String(format: "%02d", number)
        }
        return trackNumber
    }
    
    // Definiere CodingKeys, um das 'id' nicht aus JSON/XML zu lesen
    enum CodingKeys: String, CodingKey {
        case title, trackNumber
    }
}
