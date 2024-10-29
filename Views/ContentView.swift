// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager()
    @State private var showingAddAlbum = false
    @State private var showingSettings = false

    // Search and filter states
    @State private var searchText: String = ""
    @State private var selectedSearchScope: SearchScope = .all
    @State private var selectedMedium: String = "All" // Gültiger Startwert
    @State private var showDigitalOnly: Bool = false

    // State for editing albums
    @State private var albumToEdit: Album? = nil

    // Sort state
    @State private var isAscending: Bool = true

    // Optionen für Filter
    let mediums = ["All", "Vinyl", "CD", "Cassette", "Digital"]

    enum SearchScope: String, CaseIterable, Identifiable {
        case all = "All"
        case albumName = "Album Name"
        case artistName = "Artist Name"
        case trackTitle = "Track Title"

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
                        .foregroundColor(customGreen)
                    Spacer()
                    // Sort-Button
                    Button(action: {
                        withAnimation {
                            isAscending.toggle()
                        }
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .rotationEffect(isAscending ? .degrees(0) : .degrees(180))
                            .foregroundColor(customGreen)
                            .accessibilityLabel(isAscending ? "Ascending Sort" : "Descending Sort")
                    }
                    .padding(.trailing, 10)

                    // Settings-Button
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(customGreen)
                    }
                    .padding(.trailing, 10)

                    // Add-Button
                    Button(action: {
                        showingAddAlbum = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(customGreen)
                    }
                }
                .padding()

                // Suchleiste mit Scope-Auswahl
                VStack {
                    SearchBar(text: $searchText)
                        .padding(.horizontal)

                    Picker("Search in", selection: $selectedSearchScope) {
                        ForEach(SearchScope.allCases) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }

                // Filteroptionen
                HStack {
                    // Medium-Filter (inkl. "All")
                    Picker("Medium", selection: $selectedMedium) {
                        ForEach(mediums, id: \.self) { medium in
                            Text(medium).tag(medium)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundColor(customGreen)

                    // Digital-Filter
                    Toggle(isOn: $showDigitalOnly) {
                        Text("Digital")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: customGreen))
                }
                .padding(.horizontal)

                if dataManager.albums.isEmpty {
                    Text("No albums available. Please select a JSON file in the settings or add new albums.")
                        .padding()
                        .foregroundColor(.secondary)
                } else {
                    // Liste der Alben
                    List {
                        ForEach(filteredAndSortedAlbums) { album in
                            NavigationLink(destination: AlbumDetailView(album: album, dataManager: dataManager)) {
                                VStack(alignment: .leading) {
                                    Text(album.name)
                                        .font(.headline)
                                        .foregroundColor(customGreen)
                                    Text(album.artist)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
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
            .navigationBarHidden(true) // Standard-Navigationsleiste ausblenden
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

    // Filter- und Sortierlogik
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

        // Medium-Filter (inkl. "All")
        if selectedMedium != "All" {
            result = result.filter { $0.medium.lowercased() == selectedMedium.lowercased() }
        }

        // Digital-Filter
        if showDigitalOnly {
            result = result.filter { $0.digital }
        }

        // Sortieren basierend auf isAscending
        result.sort {
            if isAscending {
                return $0.name.lowercased() < $1.name.lowercased()
            } else {
                return $0.name.lowercased() > $1.name.lowercased()
            }
        }

        return result
    }

    // Album löschen
    func deleteAlbum(_ album: Album) {
        if let index = dataManager.albums.firstIndex(where: { $0.id == album.id }) {
            dataManager.albums.remove(at: index)
            dataManager.saveAlbums()
        }
    }
}
