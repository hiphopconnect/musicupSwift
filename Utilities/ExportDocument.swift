//
//  ExportDocument.swift
//  MusicUpSwift
//
//  Created by Michael Milke on 05.10.24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.json, .xml, .commaSeparatedText]
    static var writableContentTypes: [UTType] = [.json, .xml, .commaSeparatedText]
    
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
