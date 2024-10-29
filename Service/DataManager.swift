// DataManager.swift
import Foundation

class DataManager: ObservableObject {
    @Published var albums: [Album] = []

    // jsonFileURL Eigenschaft
    var jsonFileURL: URL

    // Initialisierer mit optionalem jsonFileURL
    init(jsonFileURL: URL? = nil) {
        if let url = jsonFileURL {
            self.jsonFileURL = url
        } else {
            self.jsonFileURL = DataManager.getDefaultJsonFileURL()
        }
        loadAlbums()
    }

    // Standard JSON-Datei URL
    static func getDefaultJsonFileURL() -> URL {
        // Rückgabe der Standard-URL zur JSON-Datei im Dokumentenverzeichnis der App
        let fileManager = FileManager.default
        let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docsDir.appendingPathComponent("albums.json")
    }

    // Alben laden
    func loadAlbums() {
        let url = jsonFileURL
        do {
            let data = try Data(contentsOf: url)
            if data.isEmpty {
                print("Data file is empty.")
                albums = []
                return
            }
            let decoder = JSONDecoder()
            albums = try decoder.decode([Album].self, from: data)
            print("Loaded \(albums.count) albums.")
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
                print("No existing albums.json file. This is normal on first launch.")
                albums = []
            } else {
                print("Error loading albums: \(error.localizedDescription)")
                albums = []
            }
        }
    }

    // Alben speichern
    func saveAlbums() {
        let url = jsonFileURL
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(albums)
            try data.write(to: url)
            print("Albums saved successfully to \(url.path).")
        } catch {
            print("Error saving albums: \(error.localizedDescription)")
        }
    }

    // Alben aus JSON-Daten importieren
    func importAlbumsFromJsonData(_ data: Data) throws {
        let decoder = JSONDecoder()
        do {
            let importedAlbums = try decoder.decode([Album].self, from: data)
            DispatchQueue.main.async {
                self.albums = importedAlbums
                self.saveAlbums()
                print("Imported \(importedAlbums.count) albums from JSON data.")
            }
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            throw decodingError
        } catch {
            print("Unexpected error: \(error)")
            throw error
        }
    }
}
