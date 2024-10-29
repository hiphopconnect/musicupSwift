// Track.swift
import Foundation

struct Track: Identifiable, Codable {
    var id = UUID() // Generiert eine eindeutige ID für jeden Track
    var title: String
    var trackNumber: String

    var formattedTrackNumber: String {
        if let number = Int(trackNumber) {
            return String(number)
        } else {
            return trackNumber
        }
    }

    // CodingKeys definieren, um "id" auszuschließen
    enum CodingKeys: String, CodingKey {
        case title
        case trackNumber
    }
}
