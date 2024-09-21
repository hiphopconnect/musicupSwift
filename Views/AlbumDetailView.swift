import SwiftUI

struct AlbumDetailView: View {
    var album: Album
    @ObservedObject var dataManager: DataManager
    @State private var showingEditAlbum = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Artist: \(album.artist)")
                .font(.subheadline)
            Text("Genre: \(album.genre)")
                .font(.subheadline)
            Text("Year: \(album.year)")
                .font(.subheadline)
            Text("Medium: \(album.medium)")
                .font(.subheadline)
            Text("Digital: \(album.digital ? "Ja" : "Nein")")
                .font(.subheadline)
            
            Divider()
            
            Text("Tracks:")
                .font(.headline)
            
            List {
                ForEach(album.tracks.sorted(by: { Int($0.trackNumber) ?? 0 < Int($1.trackNumber) ?? 0 })) { track in
                    HStack {
                        Text("Track \(track.formattedTrackNumber)")
                        Text(track.title)
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            Spacer()
        }
        .padding()
        .navigationTitle(album.name)
        .navigationBarItems(trailing:
            HStack {
                Button(action: {
                    showingEditAlbum = true
                }) {
                    Image(systemName: "pencil")
                }
                .padding(.trailing, 10)
                
                Button(action: {
                    deleteAlbum()
                }) {
                    Image(systemName: "trash")
                }
            }
        )
        .sheet(isPresented: $showingEditAlbum) {
            AddEditAlbumView(dataManager: dataManager, albumToEdit: album)
        }
    }
    
    func deleteAlbum() {
        if let index = dataManager.albums.firstIndex(where: { $0.id == album.id }) {
            dataManager.albums.remove(at: index)
            dataManager.saveAlbums()
        }
    }
}
