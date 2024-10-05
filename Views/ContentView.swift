import SwiftUI

// Definiere customGreen, falls nicht bereits geschehen

struct ContentView: View {
    @StateObject private var dataManager = DataManager()
    @State private var showingAddAlbum = false
    @State private var showingSettings = false

    // Such- und Filterzustände
    @State private var searchText: String = ""
    @State private var selectedSearchScope: SearchScope = .all
    @State private var selectedMedium: String = "Alle" // Gültiger Startwert
    @State private var showDigitalOnly: Bool = false

    // Zustände für Bearbeiten von Alben
    @State private var albumToEdit: Album? = nil

    // Sortierzustand
    @State private var isAscending: Bool = true

    // Optionen für Filter (Genre wurde entfernt)
    let mediums = ["Alle", "Vinyl", "CD", "Cassette", "Digital"]

    enum SearchScope: String, CaseIterable, Identifiable {
        case all = "Alle"
        case albumName = "Albumname"
        case artistName = "Künstlername"
        case trackTitle = "Tracktitel"

        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Benutzerdefinierte Navigationsleiste
                HStack {
                    Text("MusicUp")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    // Sortierbutton
                    Button(action: {
                        withAnimation {
                            isAscending.toggle()
                        }
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .rotationEffect(isAscending ? .degrees(0) : .degrees(180))
                            .accessibilityLabel(isAscending ? "Sortierung aufsteigend" : "Sortierung absteigend")
                    }
                    .padding(.trailing, 10)

                    // Einstellungen-Button
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                    .padding(.trailing, 10)

                    // Hinzufügen-Button
                    Button(action: {
                        showingAddAlbum = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                .padding()

                // Suchleiste mit Suchbereichsauswahl
                VStack {
                    SearchBar(text: $searchText)
                        .padding(.horizontal)

                    Picker("Suche in", selection: $selectedSearchScope) {
                        ForEach(SearchScope.allCases) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }

                // Filter-Optionen ohne Genre
                HStack {
                    // Medium Filter (beinhaltet "Alle")
                    Picker("Medium", selection: $selectedMedium) {
                        ForEach(mediums, id: \.self) { medium in
                            Text(medium).tag(medium)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    // Digital Filter
                    Toggle(isOn: $showDigitalOnly) {
                        Text("Digital")
                    }
                }
                .padding(.horizontal)

                if dataManager.albums.isEmpty {
                    Text("Keine Alben verfügbar. Bitte wähle eine Datei in den Einstellungen aus oder füge neue Alben hinzu.")
                        .padding()
                } else {
                    // Liste der Alben
                    List {
                        ForEach(filteredAndSortedAlbums) { album in
                            NavigationLink(destination: AlbumDetailView(album: album, dataManager: dataManager)) {
                                VStack(alignment: .leading) {
                                    Text(album.name)
                                        .font(.headline)
                                    Text(album.artist)
                                        .font(.subheadline)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteAlbum(album)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    albumToEdit = album
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(customGreen)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarHidden(true) // Verstecke die Standard-Navigationsleiste
            .sheet(isPresented: $showingAddAlbum) {
                AddEditAlbumView(dataManager: dataManager)
            }
            .sheet(item: $albumToEdit) { album in
                AddEditAlbumView(dataManager: dataManager, albumToEdit: album)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(dataManager: dataManager)
            }
        }
    }

    // Filtern und Sortieren der Alben basierend auf den aktuellen Zuständen
    var filteredAndSortedAlbums: [Album] {
        var result = dataManager.albums

        // Suchfilter
        if !searchText.isEmpty {
            switch selectedSearchScope {
            case .all:
                result = result.filter {
                    $0.name.lowercased().contains(searchText.lowercased()) ||
                    $0.artist.lowercased().contains(searchText.lowercased()) ||
                    $0.tracks.contains(where: { $0.title.lowercased().contains(searchText.lowercased()) })
                }
            case .albumName:
                result = result.filter {
                    $0.name.lowercased().contains(searchText.lowercased())
                }
            case .artistName:
                result = result.filter {
                    $0.artist.lowercased().contains(searchText.lowercased())
                }
            case .trackTitle:
                result = result.filter {
                    $0.tracks.contains(where: { $0.title.lowercased().contains(searchText.lowercased()) })
                }
            }
        }

        // Medium Filter (beinhaltet "Alle")
        if selectedMedium != "Alle" {
            result = result.filter { $0.medium == selectedMedium }
        }

        // Digital Filter
        if showDigitalOnly {
            result = result.filter { $0.digital }
        }

        // Sortierung basierend auf isAscending
        result.sort {
            if isAscending {
                return $0.name.lowercased() < $1.name.lowercased()
            } else {
                return $0.name.lowercased() > $1.name.lowercased()
            }
        }

        return result
    }

    // Löschen eines Albums
    func deleteAlbum(_ album: Album) {
        if let index = dataManager.albums.firstIndex(where: { $0.id == album.id }) {
            dataManager.albums.remove(at: index)
            dataManager.saveAlbums()
        }
    }
}
