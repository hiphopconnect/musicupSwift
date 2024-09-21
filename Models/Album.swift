import Foundation

struct Album: Identifiable, Codable {
    var id: String
    var name: String
    var artist: String
    var genre: String
    var year: String
    var medium: String
    var digital: Bool
    var tracks: [Track]
    
    // Initializer für ein neues Album
    init(id: String = UUID().uuidString, name: String, artist: String, genre: String, year: String, medium: String, digital: Bool, tracks: [Track]) {
        self.id = id
        self.name = name
        self.artist = artist
        self.genre = genre
        self.year = year
        self.medium = medium
        self.digital = digital
        self.tracks = tracks
    }
}
