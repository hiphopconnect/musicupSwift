import SwiftUI

struct AddEditAlbumView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataManager: DataManager
    
    // Wenn ein Album bearbeitet wird, wird es hier übergeben
    var albumToEdit: Album?
    
    @State private var id: String = ""
    @State private var name: String = ""
    @State private var artist: String = ""
    @State private var genre: String = "" // Freies Textfeld
    @State private var year: String = ""
    @State private var medium: String = "Vinyl" // Gültiger Startwert
    @State private var digital: Bool = false
    @State private var tracks: [Track] = []
    
    // Optionen für Medium
    let mediums = ["Vinyl", "CD", "Cassette", "Digital"]
    
    // Years Picker - Start bei 2024
    let years: [String] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((1900...currentYear).reversed()).map { String($0) }
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Album Details")) {
                    TextField("Name", text: $name)
                    TextField("Artist", text: $artist)
                    TextField("Genre", text: $genre) // Freies Textfeld
                    Picker("Year", selection: $year) { // Picker für Jahr
                        ForEach(years, id: \.self) { year in
                            Text(year).tag(year)
                        }
                    }
                    
                    Picker("Medium", selection: $medium) {
                        ForEach(mediums, id: \.self) { medium in
                            Text(medium).tag(medium)
                        }
                    }
                    
                    Toggle("Digital", isOn: $digital)
                }
                
                Section(header: Text("Tracks")) {
                    List {
                        ForEach(tracks) { track in
                            HStack {
                                Text("Track \(track.formattedTrackNumber)")
                                TextField("Title", text: Binding(
                                    get: { track.title },
                                    set: { newValue in
                                        if let index = tracks.firstIndex(where: { $0.id == track.id }) {
                                            tracks[index].title = newValue
                                        }
                                    }
                                ))
                            }
                        }
                        .onDelete(perform: deleteTracks)
                    }
                    
                    Button(action: addTrack) {
                        Text("Add Track")
                    }
                }
            }
            .navigationTitle(albumToEdit == nil ? "Add Album" : "Edit Album")
            .navigationBarItems(leading:
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing:
                Button("Save") {
                    saveAlbum()
                }
            )
            .onAppear(perform: loadAlbumData)
        }
    }
    
    func loadAlbumData() {
        if let album = albumToEdit {
            id = album.id
            name = album.name
            artist = album.artist
            genre = album.genre
            year = album.year
            medium = album.medium
            digital = album.digital
            tracks = album.tracks.sorted(by: { Int($0.trackNumber) ?? 0 < Int($1.trackNumber) ?? 0 })
        } else {
            // Generiere eine neue ID für ein neues Album
            id = UUID().uuidString
            // Set year to current year or empty
            year = String(Calendar.current.component(.year, from: Date()))
        }
    }
    
    func saveAlbum() {
        // Ensure that the year is selected
        if year.isEmpty {
            // Optionally, set a default year
            year = String(Calendar.current.component(.year, from: Date()))
        }
        
        if let album = albumToEdit, let index = dataManager.albums.firstIndex(where: { $0.id == album.id }) {
            // Aktualisiere bestehendes Album
            dataManager.albums[index].name = name
            dataManager.albums[index].artist = artist
            dataManager.albums[index].genre = genre
            dataManager.albums[index].year = year
            dataManager.albums[index].medium = medium
            dataManager.albums[index].digital = digital
            dataManager.albums[index].tracks = tracks.sorted(by: { Int($0.trackNumber) ?? 0 < Int($1.trackNumber) ?? 0 })
        } else {
            // Füge neues Album hinzu
            let newAlbum = Album(
                id: id,
                name: name,
                artist: artist,
                genre: genre,
                year: year,
                medium: medium,
                digital: digital,
                tracks: tracks.sorted(by: { Int($0.trackNumber) ?? 0 < Int($1.trackNumber) ?? 0 })
            )
            dataManager.albums.append(newAlbum)
        }
        
        dataManager.saveAlbums()
        presentationMode.wrappedValue.dismiss()
    }
    
    func addTrack() {
        let newTrackNumber = String(tracks.count + 1)
        let newTrack = Track(title: "New Track", trackNumber: newTrackNumber)
        tracks.append(newTrack)
    }
    
    func deleteTracks(at offsets: IndexSet) {
        tracks.remove(atOffsets: offsets)
        // Aktualisiere die Track-Nummern
        for index in tracks.indices {
            tracks[index].trackNumber = String(index + 1)
        }
    }
}
