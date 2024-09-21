import SwiftUI
import UniformTypeIdentifiers

// MARK: - ExportType Enum

enum ExportType: String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case json = "JSON"
    case xml = "XML"
    case csv = "CSV"
}

// MARK: - ActionType Enum

enum ActionType: Identifiable, Equatable {
    var id: String {
        switch self {
        case .changeDataSource:
            return "changeDataSource"
        case .importType(let type):
            return "importType_\(type.rawValue)"
        }
    }
    
    case changeDataSource
    case importType(ExportType)
}

// MARK: - SettingsView

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss // Für das Dismissen des Sheets
    
    @State private var selectedAction: ActionType? = nil
    @State private var showShareSheet = false
    @State private var exportURL: URL? = nil
    
    // Zustände für Fehlermeldungen und Bestätigungen
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showConfirmationAlert = false
    @State private var confirmationMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Section für den JSON-Dateipfad
                Section(header: Text("JSON File Path")) {
                    TextField("Path", text: Binding(
                        get: { UserDefaults.standard.string(forKey: dataManager.jsonFilePathKey) ?? "Keine Datei ausgewählt." },
                        set: { _ in }
                    ))
                    .disabled(true)
                    
                    Button(action: {
                        selectedAction = .changeDataSource
                    }) {
                        Text("Change JSON Path")
                    }
                }
                
                // Section für Import & Export
                Section(header: Text("Importieren & Exportieren")) {
                    // Export Buttons
                    ForEach(ExportType.allCases) { type in
                        Button(action: {
                            exportData(type: type)
                        }) {
                            Text("Export als \(type.rawValue)")
                        }
                    }
                    
                    // Import Buttons
                    ForEach(ExportType.allCases) { type in
                        Button(action: {
                            selectedAction = .importType(type)
                        }) {
                            Text("Import \(type.rawValue)")
                        }
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarItems(trailing: Button("Fertig") {
                dismiss()
            })
            .sheet(item: $selectedAction) { action in
                switch action {
                case .changeDataSource:
                    DocumentPicker(allowedTypes: [UTType.json]) { selectedURL in
                        guard let url = selectedURL else { return }
                        
                        // Kopiere die ausgewählte JSON-Datei in das Dokumentenverzeichnis
                        let fileName = "user_albums.json"
                        let destinationURL = dataManager.getDocumentsDirectory().appendingPathComponent(fileName)
                        
                        do {
                            // Entferne die vorhandene Datei, falls vorhanden
                            if FileManager.default.fileExists(atPath: destinationURL.path) {
                                try FileManager.default.removeItem(at: destinationURL)
                            }
                            // Kopiere die Datei
                            try FileManager.default.copyItem(at: url, to: destinationURL)
                            
                            // Setze den neuen Pfad in UserDefaults und lade die Alben neu
                            DispatchQueue.main.async {
                                UserDefaults.standard.set(destinationURL.path, forKey: dataManager.jsonFilePathKey)
                                dataManager.loadAlbums() // Lade die Alben aus der neuen Datei
                                
                                // Zeige eine Bestätigung an
                                confirmationMessage = "JSON-Datei ausgewählt: \(destinationURL.lastPathComponent)"
                                showConfirmationAlert = true
                            }
                        } catch {
                            print("Fehler beim Kopieren der Datei: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                errorMessage = "Fehler beim Kopieren der Datei: \(error.localizedDescription)"
                                showErrorAlert = true
                            }
                        }
                    }
                    
                case .importType(let type):
                    DocumentPicker(allowedTypes: allowedTypes(for: type)) { selectedURL in
                        guard let url = selectedURL else { return }
                        
                        // Importiere die ausgewählte Datei
                        DispatchQueue.main.async {
                            switch type {
                            case .json:
                                do {
                                    try dataManager.importAlbums(from: url.path)
                                    confirmationMessage = "JSON-Datei importiert: \(url.lastPathComponent)"
                                    showConfirmationAlert = true
                                } catch {
                                    errorMessage = "Fehler beim Importieren der JSON-Datei: \(error.localizedDescription)"
                                    showErrorAlert = true
                                }
                            case .xml:
                                do {
                                    try dataManager.importXml(from: url.path)
                                    confirmationMessage = "XML-Datei importiert: \(url.lastPathComponent)"
                                    showConfirmationAlert = true
                                } catch {
                                    errorMessage = "Fehler beim Importieren der XML-Datei: \(error.localizedDescription)"
                                    showErrorAlert = true
                                }
                            case .csv:
                                do {
                                    try dataManager.importCsv(from: url.path)
                                    confirmationMessage = "CSV-Datei importiert: \(url.lastPathComponent)"
                                    showConfirmationAlert = true
                                } catch {
                                    errorMessage = "Fehler beim Importieren der CSV-Datei: \(error.localizedDescription)"
                                    showErrorAlert = true
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Fehler"),
                      message: Text(errorMessage),
                      dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showConfirmationAlert) {
                Alert(title: Text("Erfolgreich"),
                      message: Text(confirmationMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MARK: - Export-Funktion

    func exportData(type: ExportType) {
        let exportPath = getExportURL(for: type).path
        do {
            try performExport(type: type, to: exportPath)
            exportURL = getExportURL(for: type)
            showShareSheet = true
        } catch {
            print("Fehler beim Exportieren: \(error.localizedDescription)")
            DispatchQueue.main.async {
                errorMessage = "Fehler beim Exportieren der Daten: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }
    
    // Funktion zum Exportieren der Daten
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
    
    // Funktion zum Erstellen eines temporären Export-URLs
    func getExportURL(for type: ExportType) -> URL {
        // Erstelle eine temporäre Datei im temp-Verzeichnis
        let tempDirectory = FileManager.default.temporaryDirectory
        let filename: String
        switch type {
        case .json:
            filename = "albums_export.json"
        case .xml:
            filename = "albums_export.xml"
        case .csv:
            filename = "albums_export.csv"
        }
        let exportPath = tempDirectory.appendingPathComponent(filename)
        return exportPath
    }
    
    // Funktion zur Bestimmung der erlaubten UTTypes basierend auf ExportType
    func allowedTypes(for type: ExportType) -> [UTType] {
        switch type {
        case .json:
            return [UTType.json]
        case .xml:
            return [UTType.xml]
        case .csv:
            return [UTType.commaSeparatedText]
        }
    }
    
    // MARK: - Dokumenten-Picker für die Dateiauswahl

    struct DocumentPicker: UIViewControllerRepresentable {
        var allowedTypes: [UTType]
        var onPick: (URL?) -> Void
        
        func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: true)
            picker.delegate = context.coordinator
            picker.allowsMultipleSelection = false
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(onPick: onPick)
        }
        
        class Coordinator: NSObject, UIDocumentPickerDelegate {
            var onPick: (URL?) -> Void
            
            init(onPick: @escaping (URL?) -> Void) {
                self.onPick = onPick
            }
            
            func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                onPick(urls.first)
            }
            
            func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
                onPick(nil)
            }
        }
    }
    
    // MARK: - ShareSheet zum Teilen von exportierten Dateien

    struct ShareSheet: UIViewControllerRepresentable {
        var activityItems: [Any]
        var applicationActivities: [UIActivity]? = nil
        
        func makeUIViewController(context: Context) -> UIActivityViewController {
            let controller = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: applicationActivities
            )
            return controller
        }
        
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
}
