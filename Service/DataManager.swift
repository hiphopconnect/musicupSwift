import Foundation
import Combine

class DataManager: ObservableObject {
    @Published var albums: [Album] = []
    
    let jsonFilePathKey = "jsonFilePath" // Öffentlich zugänglich
    private let defaultFileName = "albums.json"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Beobachte Änderungen in UserDefaults für den JSON-Dateipfad
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.loadAlbums()
            }
            .store(in: &cancellables)
        
        // Lade die Alben beim Initialisieren
        loadAlbums()
    }
    
    // Pfad zum Dokumentenverzeichnis der App
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Aktueller JSON-Dateipfad (aus UserDefaults oder Standardpfad)
    var jsonFilePath: String {
        UserDefaults.standard.string(forKey: jsonFilePathKey) ?? getDocumentsDirectory().appendingPathComponent(defaultFileName).path
    }
    
    // Laden der Alben aus der JSON-Datei
    func loadAlbums() {
        let path = jsonFilePath
        print("Versuche, Alben zu laden aus: \(path)") // Debugging
        
        let url = URL(fileURLWithPath: path)
        
        // Überprüfen, ob die Datei existiert
        if !FileManager.default.fileExists(atPath: url.path) {
            print("Datei existiert nicht: \(url.path)")
            // Initialisiere mit einer leeren Albenliste und speichere die Datei
            albums = []
            saveAlbums()
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            albums = try decoder.decode([Album].self, from: data)
            print("Alben erfolgreich geladen aus \(path).")
        } catch {
            print("Fehler beim Laden der Alben: \(error.localizedDescription)")
            // Initialisiere mit einer leeren Albenliste im Fehlerfall
            albums = []
            saveAlbums()
        }
    }
    
    // Speichern der Alben in die JSON-Datei
    func saveAlbums() {
        let url = URL(fileURLWithPath: jsonFilePath)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(albums)
            try data.write(to: url)
            print("Alben erfolgreich gespeichert in \(jsonFilePath).")
        } catch {
            print("Fehler beim Speichern der Alben: \(error.localizedDescription)")
        }
    }
    
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
            xmlString += "    <id>\(album.id)</id>\n"
            xmlString += "    <name>\(album.name)</name>\n"
            xmlString += "    <artist>\(album.artist)</artist>\n"
            xmlString += "    <genre>\(album.genre)</genre>\n"
            xmlString += "    <year>\(album.year)</year>\n"
            xmlString += "    <medium>\(album.medium)</medium>\n"
            xmlString += "    <digital>\(album.digital ? "true" : "false")</digital>\n"
            xmlString += "    <tracks>\n"
            for track in album.tracks.sorted(by: { Int($0.trackNumber) ?? 0 < Int($1.trackNumber) ?? 0 }) {
                xmlString += "      <track>\n"
                xmlString += "        <title>\(track.title)</title>\n"
                xmlString += "        <trackNumber>\(track.trackNumber)</trackNumber>\n"
                xmlString += "      </track>\n"
            }
            xmlString += "    </tracks>\n"
            xmlString += "  </album>\n"
        }
        xmlString += "</albums>"
        
        try xmlString.write(toFile: path, atomically: true, encoding: .utf8)
        print("XML erfolgreich exportiert nach \(path).")
    }
    
    // Exportieren als CSV
    func exportCsv(to path: String) throws {
        var csvString = "ID,Name,Artist,Genre,Year,Medium,Digital,Tracks\n"
        for album in albums {
            let tracks = album.tracks.sorted(by: { Int($0.trackNumber) ?? 0 < Int($1.trackNumber) ?? 0 }).map { "\($0.trackNumber). \($0.title)" }.joined(separator: " | ")
            let digitalString = album.digital ? "Ja" : "Nein"
            csvString += "\"\(album.id)\",\"\(album.name)\",\"\(album.artist)\",\"\(album.genre)\",\"\(album.year)\",\"\(album.medium)\",\"\(digitalString)\",\"\(tracks)\"\n"
        }
        
        try csvString.write(toFile: path, atomically: true, encoding: .utf8)
        print("CSV erfolgreich exportiert nach \(path).")
    }
    
    // Importieren von JSON
    func importAlbums(from path: String) throws {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        do {
            let importedAlbums = try decoder.decode([Album].self, from: data)
            DispatchQueue.main.async {
                self.albums = importedAlbums
                self.saveAlbums()
                print("Alben erfolgreich importiert aus \(path).")
            }
        } catch {
            print("Fehler beim Decodieren der Alben: \(error.localizedDescription)")
            throw error // Weiterwerfen des Fehlers zur weiteren Behandlung
        }
    }
    
    // Importieren von XML
    func importXml(from path: String) throws {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        
        // XML Parsing
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
    
    // Importieren von CSV
    func importCsv(from path: String) throws {
        let url = URL(fileURLWithPath: path)
        let data = try String(contentsOf: url, encoding: .utf8)
        let rows = data.components(separatedBy: "\n")
        
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
                
                let digital = columns[6].lowercased() == "ja"
                
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
}
