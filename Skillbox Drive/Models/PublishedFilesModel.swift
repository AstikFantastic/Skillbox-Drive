import Foundation

struct PublishedFilesResponse: Codable {
    let items: [PublishedFile]
    let type: String
    let limit: Int
    let offset: Int
}
struct PublishedFile: Codable {
    let name: String
    let size: Int?
    let created: String
    let mimeType: String?
    let preview: String?
    let publicURL: String?
    let path: String
    let type: String?
    
    enum CodingKeys: String, CodingKey {
        case name, size, created, preview, path, type
        case mimeType = "mime_type"
        case publicURL = "public_url"
    }
}

struct FolderResponse: Codable {
    let _embedded: Embedded
    let created: String
    let type: String
    let name: String
    let modified: String
}

struct Embedded: Codable {
    let items: [File]
}

struct File: Codable {
    let name: String?
    let created: String?
    let path: String
    let size: Int?
}
