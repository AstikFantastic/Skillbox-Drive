import Foundation

struct PublishedFilesResponse: Codable {
    let items: [PublishedFile]
    let type: String?
    let limit: Int?
    let offset: Int?
}

struct PublishedFile: Codable {
    let size: Int?
    let name: String?
    let created: String?
    let file: String?
    let preview: String?
    let path: String?
    let type: String?
    let mediaType: String?
    let mimeType: String?
    var publicURL: String?
    let embedded: Embedded?

    enum CodingKeys: String, CodingKey {
        case name, size, created, preview, path, type, file, mediaType
        case mimeType = "mime_type"
        case publicURL = "public_url"
        case embedded = "_embedded"
    }
}

struct Embedded: Codable {
    let items: [PublishedFile]
}

extension PublishedFile {
    func withNewNameAndDate(_ newName: String) -> PublishedFile {
        let currentPath = self.path ?? ""
        let directory = (currentPath as NSString).deletingLastPathComponent
        let newPath = directory + "/" + newName
        return PublishedFile(
            size: self.size,
            name: newName,
            created: self.created,
            file: self.file,
            preview: self.preview,
            path: newPath,
            type: self.type,
            mediaType: self.mediaType,
            mimeType: self.mimeType,
            publicURL: self.publicURL,
            embedded: self.embedded
        )
    }
}
