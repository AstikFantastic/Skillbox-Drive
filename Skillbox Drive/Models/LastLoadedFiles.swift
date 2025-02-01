import Foundation

struct LastLoadedFiles: Codable {
    let items: [Items]
    let limit: Int
}

struct Items: Codable {
    let size: Int
    let name: String
    let created: String
    let file: String?
    let preview: String?
    let path, sha256, type, md5: String?
    let mediaType: String?
    let mimeType: String
}
