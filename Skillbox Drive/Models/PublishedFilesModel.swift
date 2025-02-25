import Foundation

struct PublishedFilesResponse: Codable {
    
    let items: [PublishedFile]
    let type: String?
    let limit: Int?
    let offset: Int?
}
struct PublishedFile: Codable {
    let size: Int?
    let name: String
    let created: String
    let file: String?
    let preview: String?
    let path: String
    let type: String?
    let mediaType: String?
    let mimeType: String?
    var publicURL: String?
    
    enum CodingKeys: String, CodingKey {
        case name, size, created, preview, path, type, file, mediaType
        case mimeType = "mime_type"
        case publicURL = "public_url"
    }
}




