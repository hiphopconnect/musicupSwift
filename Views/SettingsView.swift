import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager

    @State private var showFileImporter = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    @State private var isFileExporterPresented = false
    @State private var exportData: Data? = nil
    @State private var selectedExportType: ExportType = .json

    @State private var showCustomAlert = false
    @State private var confirmationMessage = ""

    // Import-Optionen
    @State private var showImportOptions = false
    @State private var selectedImportType: ImportType = .json

    enum ExportType: String, CaseIterable, Identifiable {
        case json = "JSON"
        case xml = "XML"
        case csv = "CSV"

        var id: String { self.rawValue }
    }

    enum ImportType: String, CaseIterable, Identifiable {
        case json = "JSON"
        case xml = "XML"
        case csv = "CSV"

        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Datenverwaltung")) {
                    // Button zum Ändern des JSON-Pfads
                    Button(action: {
                        showFileImporter = true
                    }) {
                        Text("JSON-Pfad ändern")
                            .foregroundColor(customGreen)
                    }

                    // Import-Optionen
                    Picker("Importformat", selection: $selectedImportType) {
                        ForEach(ImportType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    Button(action: {
                        showImportOptions = true
                    }) {
                        Text("Daten importieren")
                            .foregroundColor(customGreen)
                    }
                    .actionSheet(isPresented: $showImportOptions) {
                        ActionSheet(
                            title: Text("Importieren von \(selectedImportType.rawValue)"),
                            buttons: [
                                .default(Text("Datei auswählen")) {
                                    showFileImporter = true
                                },
                                .cancel()
                            ]
                        )
                    }

                    // Export-Optionen
                    Picker("Exportformat", selection: $selectedExportType) {
                        ForEach(ExportType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    Button(action: {
                        exportData(type: selectedExportType)
                    }) {
                        Text("Daten exportieren")
                            .foregroundColor(customGreen)
                    }
                }
            }
            .navigationBarTitle("Einstellungen", displayMode: .inline)
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: allowedContentTypes(for: selectedImportType),
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
            .fileExporter(
                isPresented: $isFileExporterPresented,
                document: ExportDocument(data: exportData ?? Data()),
                contentType: contentType(for: selectedExportType),
                defaultFilename: defaultFilename(for: selectedExportType)
            ) { result in
                switch result {
                case .success(let url):
                    print("Datei erfolgreich exportiert nach \(url).")
                    confirmationMessage = "\(selectedExportType.rawValue) erfolgreich exportiert."
                    showCustomAlert = true
                case .failure(let error):
                    print("Fehler beim Exportieren: \(error.localizedDescription)")
                    errorMessage = "Fehler beim Exportieren der Daten: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .overlay(
                Group {
                    if showCustomAlert {
                        CustomAlertView(title: "Erfolgreich", message: confirmationMessage) {
                            showCustomAlert = false
                        }
                    }
                }
            )
        }
    }

    // Funktion zum Auswählen und Importieren der Datei
    func handleFileSelection(_ url: URL) {
        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Konnte nicht auf die sicherheitsbeschränkte Ressource zugreifen.")
            errorMessage = "Konnte nicht auf die ausgewählte Datei zugreifen."
            showErrorAlert = true
            return
        }

        defer {
            // Stop accessing the resource when done
            url.stopAccessingSecurityScopedResource()
        }

        do {
            let data = try Data(contentsOf: url)
            
            // Wenn die ausgewählte Datei eine andere JSON-Datei ist, kopiere sie zum festen Pfad
            if selectedImportType == .json && url.path != dataManager.getJsonFileURL().path {
                try data.write(to: dataManager.getJsonFileURL())
                print("JSON-Datei kopiert nach \(dataManager.getJsonFileURL().path).")
            }

            switch selectedImportType {
            case .json:
                try dataManager.importAlbumsFromJsonData(data)
            case .xml:
                try dataManager.importAlbumsFromXmlData(data)
            case .csv:
                try dataManager.importAlbumsFromCsvData(data)
            }

            DispatchQueue.main.async {
                confirmationMessage = "\(selectedImportType.rawValue)-Datei erfolgreich importiert."
                showCustomAlert = true
            }
        } catch {
            print("Fehler beim Importieren der Datei: \(error.localizedDescription)")
            DispatchQueue.main.async {
                errorMessage = "Fehler beim Importieren der Datei: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }

    // Funktion zum Exportieren der Daten
    func exportData(type: ExportType) {
        let exportURL = getExportURL(for: type)
        let exportPath = exportURL.path
        do {
            try performExport(type: type, to: exportPath)
            let data = try Data(contentsOf: exportURL)
            DispatchQueue.main.async {
                self.exportData = data
                self.isFileExporterPresented = true
            }
        } catch {
            print("Fehler beim Exportieren: \(error.localizedDescription)")
            DispatchQueue.main.async {
                errorMessage = "Fehler beim Exportieren der Daten: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }

    // Hilfsfunktionen und -typen
    func getExportURL(for type: ExportType) -> URL {
        let fileName = defaultFilename(for: type)
        return FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    }

    func performExport(type: ExportType, to path: String) throws {
        switch type {
        case .json:
            try dataManager.exportJson(to: path)
        case .xml:
            try dataManager.exportXml(to: path)
        case .csv:
            try dataManager.exportCsv(to: path)
        }
    }

    func contentType(for type: ExportType) -> UTType {
        switch type {
        case .json:
            return .json
        case .xml:
            return .xml
        case .csv:
            return .commaSeparatedText
        }
    }

    func allowedContentTypes(for type: ImportType) -> [UTType] {
        switch type {
        case .json:
            return [.json]
        case .xml:
            return [.xml]
        case .csv:
            return [.commaSeparatedText]
        }
    }

    func defaultFilename(for type: ExportType) -> String {
        switch type {
        case .json:
            return "albums_export.json"
        case .xml:
            return "albums_export.xml"
        case .csv:
            return "albums_export.csv"
        }
    }

    // Definition des Exportdokuments
    struct ExportDocument: FileDocument {
        static var readableContentTypes: [UTType] = []
        
        var data: Data
        
        init(data: Data) {
            self.data = data
        }
        
        init(configuration: ReadConfiguration) throws {
            self.data = Data()
        }
        
        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            return FileWrapper(regularFileWithContents: data)
        }
    }

    // Benutzerdefinierter Alert
    struct CustomAlertView: View {
        var title: String
        var message: String
        var onDismiss: () -> Void

        var body: some View {
            VStack(spacing: 16) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(customGreen)
                Text(message)
                    .multilineTextAlignment(.center)
                Button(action: onDismiss) {
                    Text("OK")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(customGreen)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 10)
            .padding()
        }
    }
}
