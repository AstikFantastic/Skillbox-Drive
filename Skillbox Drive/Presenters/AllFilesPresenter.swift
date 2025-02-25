import UIKit

protocol FilesView: AnyObject {
    func showLoading()
    func hideLoading()
    func showAllFiles(_ files: [File])
    func showFolderData(_ files: [File])
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
        
        let dispatchGroup = DispatchGroup()
        var files: [File] = []
        var dirs: [File] = []
        
        dispatchGroup.enter()
        apiService.fetchAllFiles(oAuthToken: oAuthToken,
                                  baseURL: baseURL,
                                  path: path,
                                  limit: limit,
                                  offset: offset,
                                  sort: sort,
                                  completion: { result in
            switch result {
            case .success(let fetchedFiles):
                files = fetchedFiles
            case .failure(let error):
                print("Ошибка получения файлов: \(error)")
            }
            dispatchGroup.leave()
        })
        
        dispatchGroup.enter()
        apiService.fetchAllDirs(oAuthToken: oAuthToken,
                                 baseURL: baseURL,
                                 path: path,
                                 limit: limit,
                                 offset: offset,
                                 sort: sort,
                                 completion: { result in
            switch result {
            case .success(let fetchedDirs):
                dirs = fetchedDirs
            case .failure(let error):
                print("Ошибка получения папок: \(error)")
            }
            dispatchGroup.leave()
        })
        
        dispatchGroup.notify(queue: .main) {
            let allItems = dirs + files
            self.view?.hideLoading()
            if !allItems.isEmpty {
                // Можно сохранить в кэш, если нужно:
                // CoreDataManager.shared.savePublishedFiles(allItems)
                self.view?.showAllFiles(allItems)
            } else {
//                let cachedFiles = CoreDataManager.shared.fetchPublishedFiles()
//                if !cachedFiles.isEmpty {
//                    print("Загружаем данные из кэша")
//                    self.view?.showAllFiles(cachedFiles)
//                } else {
//                    self.view?.showError(NSError(domain: "APIError", code: 0,
//                                                 userInfo: [NSLocalizedDescriptionKey: "Нет доступных данных"]))
//                }
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
