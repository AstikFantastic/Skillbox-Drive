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

    enum CodingKeys: String, CodingKey {
        case name, size, created, preview, path
        case mimeType = "mime_type"
        case publicURL = "public_url"
    }
}
