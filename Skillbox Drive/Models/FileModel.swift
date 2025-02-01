import UIKit

struct FileModel {
    let name: String
    let creationDate: Date
    let fileType: FileType
    let fileData: String
}

enum FileType {
    case image
}
