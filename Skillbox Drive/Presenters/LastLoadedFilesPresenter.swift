import UIKit

protocol LastFilesView: AnyObject {
    func showLoading()
    func hideLoading()
    func showAllFiles(_ files: [PublishedFile])
    func showFolderData(_ files: [File])
    func showError(_ error: Error)
}

class LastLoadedFilesPresenter {
    
    weak var view: LastFilesView?
    private let apiService: APIService
    private let oAuthToken: String
    
    init(view: LastFilesView, oAuthToken: String, apiService: APIService) {
        self.view = view
        self.oAuthToken = oAuthToken
        self.apiService = apiService
    }
    
    func fetchLastLoadedFiles(limit: Int = 50, offset: Int = 0, baseURL: String = APIEndpoint.lastUpLoaded.url) {
        view?.showLoading()
        
        let dispatchGroup = DispatchGroup()
        var files: [PublishedFile] = []
        var dirs: [PublishedFile] = []
        
        dispatchGroup.enter()
        apiService.fetchFiles(oAuthToken: oAuthToken, baseURL: baseURL, limit: limit, offset: 0) { result in
            switch result {
            case .success(let fetchedFiles):
                files = fetchedFiles
            case .failure(let error):
                print("Ошибка получения файлов: \(error)")
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        apiService.fetchDirs(oAuthToken: oAuthToken, baseURL: baseURL, limit: limit, offset: 0) { result in
            switch result {
            case .success(let fetchedDirs):
                dirs = fetchedDirs
            case .failure(let error):
                print("Ошибка получения папок: \(error)")
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            let allItems = dirs + files
            self.view?.hideLoading()
            if !allItems.isEmpty {
                CoreDataManager.shared.savePublishedFiles(allItems)
                self.view?.showAllFiles(allItems)
            } else {
//                self.view?.showNoInternetBanner(message: "No internet connection")
                let cachedFiles = CoreDataManager.shared.fetchPublishedFiles()
                if !cachedFiles.isEmpty {
                    print("Загружаем данные из кэша")
                    self.view?.showAllFiles(cachedFiles)
                } else {
                    self.view?.showError(NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Нет доступных данных"]))
                }
            }
        }
    }
    
    func fetchFolderContents(path: String, limit: Int = 50, baseURL: String = APIEndpoint.lastUpLoaded.url, offset: Int = 0, previewSize: String = "120x120", previewCrop: String = "true") {
        view?.showLoading()
        print("Fetching contents for folder at path: \(path)")
        
        apiService.fetchFolderMetadata(oAuthToken: oAuthToken, baseURL: baseURL, path: path, limit: limit, offset: offset, previewSize: previewSize, previewCrop: previewCrop) { result in
            switch result {
            case .success(let fetchedFiles):
                print("Successfully fetched folder contents: \(fetchedFiles)")
                self.view?.hideLoading()
                self.view?.showFolderData(fetchedFiles)
            case .failure(let error):
                print("Error fetching folder contents: \(error)")
                self.view?.showError(error)
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
