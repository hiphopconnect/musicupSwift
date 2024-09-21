import Foundation

class XMLAlbumParser: NSObject, XMLParserDelegate {
    var albums: [Album] = []
    private var currentElement = ""
    private var currentAlbum: Album?
    private var currentTrack: Track?
    private var currentTracks: [Track] = []
    
    private var currentValue: String = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "album" {
            currentTracks = []
            currentAlbum = Album(id: "", name: "", artist: "", genre: "", year: "", medium: "", digital: false, tracks: [])
        }
        if elementName == "track" {
            currentTrack = Track(title: "", trackNumber: "")
        }
        currentValue = ""
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        if elementName == "id" {
            currentAlbum?.id = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "name" {
            currentAlbum?.name = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "artist" {
            currentAlbum?.artist = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "genre" {
            currentAlbum?.genre = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "year" {
            currentAlbum?.year = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "medium" {
            currentAlbum?.medium = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "digital" {
            currentAlbum?.digital = currentValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
        } else if elementName == "trackNumber" {
            currentTrack?.trackNumber = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "title" {
            currentTrack?.title = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "track" {
            if let track = currentTrack {
                currentTracks.append(track)
            }
            currentTrack = nil
        } else if elementName == "album" {
            if var album = currentAlbum {
                album.tracks = currentTracks
                albums.append(album)
            }
            currentAlbum = nil
        }
    }
}
