import Foundation

struct Track: Identifiable, Codable, Equatable {
    var id: UUID = UUID() // Automatisch generierte UUID
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
    
    // Initializer für Flexibilität
    init(id: UUID = UUID(), title: String, trackNumber: String) {
        self.id = id
        self.title = title
        self.trackNumber = trackNumber
    }
}
