import UIKit

protocol PublishedFilesView: AnyObject {
    func showLoading()
    func hideLoading()
    func showAllFiles(_ files: [PublishedFile])
    func showFolderData(_ files: [PublishedFile])
    func showError(_ error: Error)
    func showNoInternetBanner(message: String)
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
    
    var errorFiles: Error?
    var errorDirs: Error?
    
    func fetchPublishedFiles(limit: Int = 100, offset: Int = 0, baseURL: String = APIEndpoint.publicResources.url) {
        view?.showLoading()
        
        let dispatchGroup = DispatchGroup()
        var files: [PublishedFile] = []
        var dirs: [PublishedFile] = []
        
       
        dispatchGroup.enter()
        apiService.fetchFiles(oAuthToken: oAuthToken, baseURL: baseURL, limit: limit, offset: offset) { result in
            switch result {
            case .success(let fetchedFiles):
                files = fetchedFiles
            case .failure(let error):
                self.errorFiles = error
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        apiService.fetchDirs(oAuthToken: oAuthToken, baseURL: baseURL, limit: limit, offset: offset) { result in
            switch result {
            case .success(let fetchedDirs):
                dirs = fetchedDirs
            case .failure(let error):
                self.errorDirs = error
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.view?.hideLoading()
            if let error = self.errorFiles ?? self.errorDirs,
               (error as NSError).code == NSURLErrorNotConnectedToInternet ||
                (error as NSError).code == NSURLErrorCannotFindHost {
                // Нет интернет-соединения – показываем баннер и загружаем кэш
                self.view?.showNoInternetBanner(message: "No internet. Loading cache data.")
                let cachedFiles = CoreDataManager.shared.fetchPublishedFiles()
                self.view?.showAllFiles(cachedFiles)
            } else {
                let allItems = dirs + files
                CoreDataManager.shared.savePublishedFiles(allItems)
                self.view?.showAllFiles(allItems)
            }
        }
    }
        
        func fetchFolderContents(path: String,
                                 limit: Int = 100,
                                 baseURL: String = APIEndpoint.publicResources.url,
                                 offset: Int = 0,
                                 previewSize: String = "120x120",
                                 previewCrop: String = "true") {
            view?.showLoading()
            print("Fetching contents for folder at path: \(path)")
            
            apiService.fetchFolderMetadata(oAuthToken: oAuthToken,
                                           baseURL: baseURL,
                                           path: path,
                                           limit: limit,
                                           offset: offset,
                                           previewSize: previewSize,
                                           previewCrop: previewCrop) { result in
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
        
        func unpublishRespopnse(path: String) {
            apiService.unpublishResource(oAuthToken: oAuthToken,
                                         baseURL: APIEndpoint.unpublish.url,
                                         path: path) { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.fetchPublishedFiles(limit: 100, offset: 0)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.view?.showError(error)
                    }
                }
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

