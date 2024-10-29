import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager

    @State private var showFileImporter = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    // Funktion zur Ermittlung der App-Version
    func getAppVersion() -> String {
        if let infoDictionary = Bundle.main.infoDictionary {
            let version = infoDictionary["CFBundleShortVersionString"] as? String ?? "Unbekannt"
            let build = infoDictionary["CFBundleVersion"] as? String ?? "Unbekannt"
            return "Version \(version) (Build \(build))"
        }
        return "Version Unbekannt"
    }

    // Zähler für Statistiken
    @State private var vinylCount = 0
    @State private var cdCount = 0
    @State private var cassetteCount = 0
    @State private var digitalCount = 0
    @State private var digitalYesCount = 0
    @State private var digitalNoCount = 0

    var body: some View {
        NavigationView {
            Form {
                // Abschnitt für App-Informationen
                Section(header: Text("App-Informationen")
                            .foregroundColor(customGreen)) {
                    Text("Maintainer: Michael Milke (Nobo)")
                        .foregroundColor(.primary)
                    Link("Email: nobo_code@posteo.de", destination: URL(string: "mailto:nobo_code@posteo.de")!)
                        .foregroundColor(customGreen)
                    Link("GitHub: hiphopconnect/musicupSwift", destination: URL(string: "https://github.com/hiphopconnect/musicupSwift/")!)
                        .foregroundColor(customGreen)
                    Text("License: GPL-3.0")
                        .foregroundColor(.primary)
                    Text(getAppVersion())
                        .foregroundColor(.primary)
                }

                // Abschnitt für Statistiken
                Section(header: Text("Statistiken")
                            .foregroundColor(customGreen)) {
                    HStack {
                        Text("Gesamtanzahl der Alben:")
                        Spacer()
                        Text("\(dataManager.albums.count)")
                            .foregroundColor(customGreen)
                    }
                    HStack {
                        Text("Vinyl-Alben:")
                        Spacer()
                        Text("\(vinylCount)")
                            .foregroundColor(customGreen)
                    }
                    HStack {
                        Text("CD-Alben:")
                        Spacer()
                        Text("\(cdCount)")
                            .foregroundColor(customGreen)
                    }
                    HStack {
                        Text("Cassette-Alben:")
                        Spacer()
                        Text("\(cassetteCount)")
                            .foregroundColor(customGreen)
                    }
                    HStack {
                        Text("Digital-Alben:")
                        Spacer()
                        Text("\(digitalCount)")
                            .foregroundColor(customGreen)
                    }
                    HStack {
                        Text("Alben mit digitaler Kopie:")
                        Spacer()
                        Text("\(digitalYesCount)")
                            .foregroundColor(customGreen)
                    }
                    HStack {
                        Text("Alben ohne digitale Kopie:")
                        Spacer()
                        Text("\(digitalNoCount)")
                            .foregroundColor(customGreen)
                    }
                }

                // Abschnitt für Datenverwaltung
                Section(header: Text("Datenverwaltung")
                            .foregroundColor(customGreen)) {
                    Button(action: {
                        showFileImporter = true
                    }) {
                        Text("JSON-Pfad ändern")
                            .foregroundColor(customGreen)
                    }
                }
            }
            .navigationBarTitle("Einstellungen", displayMode: .inline)
            .onAppear(perform: updateCounts)
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    handleFileSelection(url)
                case .failure(let error):
                    print("Fehler beim Auswählen der Datei: \(error.localizedDescription)")
                    errorMessage = "Fehler beim Auswählen der Datei: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Fehler"),
                      message: Text(errorMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }

    // Funktion zur Aktualisierung der Zähler
    func updateCounts() {
        let albumsToCount = dataManager.albums

        vinylCount = 0
        cdCount = 0
        cassetteCount = 0
        digitalCount = 0
        digitalYesCount = 0
        digitalNoCount = 0

        for album in albumsToCount {
            switch album.medium.lowercased() {
            case "vinyl":
                vinylCount += 1
            case "cd":
                cdCount += 1
            case "cassette":
                cassetteCount += 1
            case "digital":
                digitalCount += 1
            default:
                break
            }

            if album.digital {
                digitalYesCount += 1
            } else {
                digitalNoCount += 1
            }
        }
    }

    // Funktion zur Auswahl und zum Import der JSON-Datei
    func handleFileSelection(_ url: URL) {
        // Zugriff auf die sicherheitsabhängige Ressource starten
        guard url.startAccessingSecurityScopedResource() else {
            print("Zugriff auf die sicherheitsabhängige Ressource fehlgeschlagen.")
            errorMessage = "Zugriff auf die ausgewählte Datei fehlgeschlagen."
            showErrorAlert = true
            return
        }

        defer {
            // Zugriff auf die Ressource beenden, wenn die Funktion beendet wird
            url.stopAccessingSecurityScopedResource()
        }

        do {
            let data = try Data(contentsOf: url)
            print("Daten aus der ausgewählten Datei gelesen: \(data.count) Bytes")

            // Überprüfen, ob die Datei leer ist
            if data.isEmpty {
                print("Die ausgewählte Datei ist leer.")
                throw NSError(domain: "Ausgewählte Datei ist leer.", code: 0, userInfo: nil)
            }

            // Die ausgewählte JSON-Datei in das Verzeichnis der App kopieren
            let destinationURL = dataManager.jsonFileURL
            if url.path != destinationURL.path {
                try data.write(to: destinationURL)
                print("JSON-Datei nach \(destinationURL.path) kopiert.")
            }

            // Alben aus den JSON-Daten importieren
            try dataManager.importAlbumsFromJsonData(data)

            DispatchQueue.main.async {
                // Zähler nach dem Import aktualisieren
                updateCounts()
                print("JSON-Datei erfolgreich importiert.")
            }
        } catch {
            print("Fehler beim Importieren der Datei: \(error)")
            DispatchQueue.main.async {
                errorMessage = "Fehler beim Importieren der Datei: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }
}
