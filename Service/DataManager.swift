import Foundation
import Combine

class DataManager: ObservableObject {
    @Published var albums: [Album] = []
    
    private let jsonFileName = "user_albums.json"
    
    init() {
        loadAlbums()
    }
    
    // Pfad zum Dokumentenverzeichnis der App
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Vollständiger URL zur JSON-Datei
    private var jsonFileURL: URL {
        getDocumentsDirectory().appendingPathComponent(jsonFileName)
    }
    
    // Getter-Methode für jsonFileURL
    func getJsonFileURL() -> URL {
        return jsonFileURL
    }
    
    // Laden der Alben aus der JSON-Datei
    func loadAlbums() {
        let url = jsonFileURL
        
        if !FileManager.default.fileExists(atPath: url.path) {
            // Erstelle eine leere JSON-Datei
            do {
                let emptyData = try JSONEncoder().encode([Album]())
                try emptyData.write(to: url)
                print("Leere JSON-Datei erstellt unter \(url.path).")
            } catch {
                print("Fehler beim Erstellen der leeren JSON-Datei: \(error.localizedDescription)")
            }
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let loadedAlbums = try decoder.decode([Album].self, from: data)
            DispatchQueue.main.async {
                self.albums = loadedAlbums
                print("Alben erfolgreich geladen aus \(url.path).")
            }
        } catch {
            print("Fehler beim Laden der Alben: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.albums = []
            }
        }
    }
    
    // Speichern der Alben in die JSON-Datei
    func saveAlbums() {
        let url = jsonFileURL
        
        DispatchQueue.global(qos: .background).async {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(self.albums)
                try data.write(to: url)
                print("Alben erfolgreich gespeichert in \(self.getJsonFileURL().path).")
            } catch {
                print("Fehler beim Speichern der Alben: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Export-Funktionen
    
    // Exportieren als JSON
    func exportJson(to path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(albums)
        let url = URL(fileURLWithPath: path)
        try data.write(to: url)
        print("JSON erfolgreich exportiert nach \(path).")
    }
    
    // Exportieren als XML
    func exportXml(to path: String) throws {
        var xmlString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<albums>\n"
        for album in albums {
            xmlString += "  <album>\n"
            xmlString += "    <id>\(escapeXML(album.id))</id>\n"
            xmlString += "    <name>\(escapeXML(album.name))</name>\n"
            xmlString += "    <artist>\(escapeXML(album.artist))</artist>\n"
            xmlString += "    <genre>\(escapeXML(album.genre))</genre>\n"
            xmlString += "    <year>\(escapeXML(album.year))</year>\n"
            xmlString += "    <medium>\(escapeXML(album.medium))</medium>\n"
            xmlString += "    <digital>\(album.digital ? "true" : "false")</digital>\n"
            xmlString += "    <tracks>\n"
            for track in album.tracks.sorted(by: { Int($0.trackNumber) ?? 0 < Int($1.trackNumber) ?? 0 }) {
                xmlString += "      <track>\n"
                xmlString += "        <title>\(escapeXML(track.title))</title>\n"
                xmlString += "        <trackNumber>\(escapeXML(track.trackNumber))</trackNumber>\n"
                xmlString += "      </track>\n"
            }
            xmlString += "    </tracks>\n"
            xmlString += "  </album>\n"
        }
        xmlString += "</albums>"
        
        let url = URL(fileURLWithPath: path)
        try xmlString.write(to: url, atomically: true, encoding: .utf8)
        print("XML erfolgreich exportiert nach \(path).")
    }
    
    // Exportieren als CSV
    func exportCsv(to path: String) throws {
        var csvString = "ID,Name,Artist,Genre,Year,Medium,Digital,Tracks\n"
        for album in albums {
            let tracks = album.tracks.sorted(by: { Int($0.trackNumber) ?? 0 < Int($1.trackNumber) ?? 0 }).map { "\($0.trackNumber). \($0.title)" }.joined(separator: " | ")
            let digitalString = album.digital ? "Ja" : "Nein"
            csvString += "\"\(escapeCSV(album.id))\",\"\(escapeCSV(album.name))\",\"\(escapeCSV(album.artist))\",\"\(escapeCSV(album.genre))\",\"\(escapeCSV(album.year))\",\"\(escapeCSV(album.medium))\",\"\(digitalString)\",\"\(escapeCSV(tracks))\"\n"
        }
        
        let url = URL(fileURLWithPath: path)
        try csvString.write(to: url, atomically: true, encoding: .utf8)
        print("CSV erfolgreich exportiert nach \(path).")
    }
    
    // MARK: - Import-Funktionen
    
    // Importieren von JSON aus Data
    func importAlbumsFromJsonData(_ data: Data) throws {
        let decoder = JSONDecoder()
        do {
            let importedAlbums = try decoder.decode([Album].self, from: data)
            DispatchQueue.main.async {
                self.albums = importedAlbums
                self.saveAlbums()
                print("Alben erfolgreich aus JSON importiert.")
            }
        } catch {
            print("Fehler beim Decodieren der JSON-Daten: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Importieren von XML aus Data
    func importAlbumsFromXmlData(_ data: Data) throws {
        let parser = XMLParser(data: data)
        let xmlDelegate = XMLAlbumParser()
        parser.delegate = xmlDelegate
        
        if parser.parse() {
            DispatchQueue.main.async {
                self.albums = xmlDelegate.albums
                self.saveAlbums()
                print("Alben erfolgreich aus XML importiert.")
            }
        } else {
            if let error = parser.parserError {
                print("Fehler beim Parsen der XML: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    // Importieren von CSV aus Data
    func importAlbumsFromCsvData(_ data: Data) throws {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "DataManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ungültige CSV-Daten"])
        }
        
        let rows = csvString.components(separatedBy: "\n")
        
        var importedAlbums: [Album] = []
        for row in rows.dropFirst() { // Überspringe die Header-Zeile
            let columns = row.components(separatedBy: "\",\"").map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
            if columns.count >= 8 {
                let tracksString = columns[7]
                let trackComponents = tracksString.components(separatedBy: " | ")
                var tracks: [Track] = []
                for track in trackComponents {
                    let parts = track.components(separatedBy: ". ")
                    if parts.count == 2, let trackNumber = parts.first, let title = parts.last {
                        let newTrack = Track(title: title, trackNumber: trackNumber)
                        tracks.append(newTrack)
                    }
                }
                
                let digital = columns[6].lowercased() == "ja" || columns[6].lowercased() == "yes"
                
                let newAlbum = Album(
                    id: columns[0],
                    name: columns[1],
                    artist: columns[2],
                    genre: columns[3],
                    year: columns[4],
                    medium: columns[5],
                    digital: digital,
                    tracks: tracks
                )
                importedAlbums.append(newAlbum)
            }
        }
        
        DispatchQueue.main.async {
            self.albums = importedAlbums
            self.saveAlbums()
            print("Alben erfolgreich aus CSV importiert.")
        }
    }
    
    // MARK: - Helper Functions for Escaping
    
    // Funktion zum Escapen von XML-Sonderzeichen
    func escapeXML(_ string: String) -> String {
        var escaped = string
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        escaped = escaped.replacingOccurrences(of: "'", with: "&apos;")
        return escaped
    }
    
    // Funktion zum Escapen von CSV-Sonderzeichen (z.B. Kommas und Anführungszeichen)
    func escapeCSV(_ string: String) -> String {
        var escaped = string
        escaped = escaped.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            escaped = "\"\(escaped)\""
        }
        return escaped
    }
    
    // MARK: - XML Parsing Helper
    
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
                    if let track = currentTrack {
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
}
