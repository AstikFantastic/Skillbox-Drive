enum APIEndpoint: String {
    
    case baseURL = "https://cloud-api.yandex.net/v1/disk/"
    case publicResources = "https://cloud-api.yandex.net/v1/disk/resources/public"
    case publish = "https://cloud-api.yandex.net/v1/disk/resources/publish"
    
    case lastUpLoaded = "https://cloud-api.yandex.net/v1/disk/resources/last-uploaded"
    case allFiles = "https://cloud-api.yandex.net/v1/disk/resources/files"
    case resources = "https://cloud-api.yandex.net/v1/disk/resources"
    case unpublish = "https://cloud-api.yandex.net/v1/disk/resources/unpublish"
    
    var url: String { self.rawValue }
}

