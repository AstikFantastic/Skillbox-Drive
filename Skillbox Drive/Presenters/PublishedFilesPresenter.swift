import UIKit

protocol PublishedFilesView: AnyObject {
    func showLoading()
    func hideLoading()
    func showAllFiles(_ files: [PublishedFile])
    func showError(_ error: Error)
}

class PublishedFilesPresenter {
    weak var view: PublishedFilesView?
    private let apiService: APIService
    private let oAuthToken: String

    init(view: PublishedFilesView, oAuthToken: String, apiService: APIService) {
        self.view = view
        self.oAuthToken = oAuthToken
        self.apiService = apiService
    }

    func fetchLastLoadedFiles(limit: Int = 100, offset: Int = 0) {
        view?.showLoading()
        
        let dispatchGroup = DispatchGroup()
        var files: [PublishedFile] = []
        var dir: [PublishedFile] = []
        
        dispatchGroup.enter()
        
        apiService.fetchFiles(oAuthToken: oAuthToken, limit: limit) { result in
            switch result {
            case .success(let fetchedFiles):
                files = fetchedFiles
            case .failure(let error):
                print("Error fetching files: \(error)")
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        
        apiService.fetchDirs(oAuthToken: oAuthToken, limit: limit) { result in
            switch result {
            case .success(let fetchedDirs):
                dir = fetchedDirs
            case .failure(let error):
                print("Error fetching directories: \(error)")
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            let allItems = dir + files
            self.view?.hideLoading()
            self.view?.showAllFiles(allItems)
        }
    }

    func formattedFileSize(from size: Int?) -> String {
        guard let size = size else { return "Unknown size" }
        let mb = Double(size) / 1_048_576
        if mb < 1 {
            let kb = Double(size) / 1024
            return String(format: "%.2f KB", kb)
        } else if mb < 1024 {
            return String(format: "%.2f MB", mb)
        } else {
            let gb = mb / 1024
            return String(format: "%.2f GB", gb)
        }
    }
}
