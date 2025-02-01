import UIKit

struct AllFilesModel: Decodable {
    let items: [Item]
    let limit: Int
    let offset: Int
}

struct Item: Decodable {
    let antivirusStatus: String?
    let size: Int?
    let name: String
    let created: String?
    let modified: String?
    let mimeType: String?
    let file: String?
    let preview: String?
    let path: String?
    let mediaType: String?
    let sha256: String?
    let type: String?
    let md5: String?
    let sizes: [FileSize]?
}

struct FileSize: Decodable {
    let url: String
    let name: String
}
