import Foundation

struct ProfileModel: Decodable {
    let trashSize: Int
    let totalSpace: Int
    let usedSpace: Int
    let systemFolders: SystemFolders
    
    enum CodingKeys: String, CodingKey {
        case trashSize = "trash_size"
        case totalSpace = "total_space"
        case usedSpace = "used_space"
        case systemFolders = "system_folders"
    }
}

struct SystemFolders: Decodable {
    let applications: String
    let downloads: String
}
