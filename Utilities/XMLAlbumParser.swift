import Foundation

class XMLAlbumParser: NSObject, XMLParserDelegate {
    var albums: [Album] = []
    
    private var currentElement = ""
    private var currentAlbum: Album?
    private var currentTrack: Track?
    private var currentTracks: [Track] = []
    
    private var foundCharacters = ""
    
    // Detaillierte Logs hinzufügen
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("XML Parsing Fehler: \(parseError.localizedDescription)")
    }
    
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        print("XML Validation Fehler: \(validationError.localizedDescription)")
    }
    
    // Start eines Elements
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        print("Start Element: \(elementName)")
        
        if elementName == "album" {
            currentAlbum = Album(id: "", name: "", artist: "", genre: "", year: "", medium: "", digital: false, tracks: [])
            currentTracks = []
        } else if elementName == "track" {
            currentTrack = Track(title: "", trackNumber: "")
        }
        
        foundCharacters = ""
    }
    
    // Gefundene Zeichen
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        foundCharacters += string
        print("Found Characters: \(string)")
    }
    
    // Ende eines Elements
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        print("End Element: \(elementName)")
        
        if var album = currentAlbum {
            switch elementName {
            case "id":
                album.id = foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
                print("Set Album ID: \(album.id)")
            case "name":
                album.name = foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
                print("Set Album Name: \(album.name)")
            case "artist":
                album.artist = foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
                print("Set Album Artist: \(album.artist)")
            case "genre":
                album.genre = foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
                print("Set Album Genre: \(album.genre)")
            case "year":
                album.year = foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
                print("Set Album Year: \(album.year)")
            case "medium":
                album.medium = foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
                print("Set Album Medium: \(album.medium)")
            case "digital":
                let digitalString = foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                album.digital = digitalString == "true" || digitalString == "yes"
                print("Set Album Digital: \(album.digital)")
            case "track":
                if var track = currentTrack {
                    // Überprüfe, ob trackNumber vorhanden ist
                    if track.trackNumber.isEmpty {
                        print("Warnung: trackNumber fehlt für Track '\(track.title)'")
                        // Setze einen Standardwert oder ignoriere den Track
                        track.trackNumber = "0" // Beispiel: Standardwert
                    }
                    currentTracks.append(track)
                    print("Added Track: \(track.title) - \(track.trackNumber)")
                    currentTrack = nil
                }
            case "title":
                currentTrack?.title = foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
                print("Set Track Title: \(currentTrack?.title ?? "")")
            case "trackNumber":
                currentTrack?.trackNumber = foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
                print("Set Track Number: \(currentTrack?.trackNumber ?? "")")
            case "tracks":
                album.tracks = currentTracks
                print("Set Album Tracks Count: \(album.tracks.count)")
            case "album":
                albums.append(album)
                print("Added Album: \(album.name)")
                currentAlbum = nil
            default:
                break
            }
            currentAlbum = album
        }
        
        foundCharacters = ""
    }
}
