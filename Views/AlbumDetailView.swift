// AlbumDetailView.swift
import SwiftUI

struct AlbumDetailView: View {
    var album: Album
    @ObservedObject var dataManager: DataManager
    @State private var showingEditAlbum = false
    @State private var showDeleteConfirmation = false

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
            Text("Digital: \(album.digital ? "Yes" : "No")")
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
                        .foregroundColor(customGreen)
                }
                .padding(.trailing, 10)

                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        )
        .sheet(isPresented: $showingEditAlbum) {
            AddEditAlbumView(dataManager: dataManager, albumToEdit: album)
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Album"),
                message: Text("Are you sure you want to delete this album?"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteAlbum()
                },
                secondaryButton: .cancel()
            )
        }
    }

    func deleteAlbum() {
        if let index = dataManager.albums.firstIndex(where: { $0.id == album.id }) {
            dataManager.albums.remove(at: index)
            dataManager.saveAlbums()
        }
    }
}
