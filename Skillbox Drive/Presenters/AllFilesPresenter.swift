import UIKit

protocol FilesView: AnyObject {
    func showLoading()
    func hideLoading()
    func showAllFiles(_ files: [PublishedFile])
    func showError(_ error: Error)
}

class AllFilesPresenter {
    
    weak var view: FilesView?
    private let apiService: APIService
    private let oAuthToken: String
    
    init(view: FilesView, oAuthToken: String, apiService: APIService) {
        self.view = view
        self.oAuthToken = oAuthToken
        self.apiService = apiService
    }
    
    func fetchAllFiles(path: String = "disk:/", limit: Int = 100, offset: Int = 0, baseURL: String = APIEndpoint.resources.url, sort: String = "created") {
        view?.showLoading()
        
        apiService.fetchAllFilesAndFolders(oAuthToken: oAuthToken, baseURL: baseURL, path: path, limit: limit, offset: offset, sort: sort) { result in
            switch result {
            case .success(let fetchedFiles):
                self.view?.hideLoading()
                self.view?.showAllFiles(fetchedFiles)
            case .failure(let error):
                print("Ошибка получения файлов: \(error)")
            }
        }
    }
    
    func formattedFileSize(from size: Int?) -> String {
        guard let size = size else { return "Unknown size" }
        let mb = Double(size) / 1_048_576
        if mb < 1 {
            let kb = Double(size) / 1024
            return String(format: "%.2f KB", kb)
        } else if mb >= 1 && mb < 1024 {
            return String(format: "%.2f MB", mb)
        } else {
            let gb = mb / 1024
            return String(format: "%.2f GB", gb)
        }
    }
}
