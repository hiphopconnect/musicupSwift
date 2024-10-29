// Album.swift
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
}
