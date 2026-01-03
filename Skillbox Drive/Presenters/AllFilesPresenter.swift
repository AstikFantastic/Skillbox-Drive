
import UIKit

protocol FilesView: AnyObject {
    func showLoading()
    func hideLoading()
    func showAllFiles(_ files: [PublishedFile])
    func showFolderData(_ files: [PublishedFile])
    func showError(_ error: Error)
    func showNoInternetBanner(message: String)
}

class AllFilesPresenter {
    
    weak var view: FilesView?
    private let apiService: APIService
    private let oAuthToken: String
    
    private var limitAll: Int = 20
    private var offsetAll: Int = 0
    private var isLoadingAll: Bool = false
    private var allFilesLoaded: Bool = false
    private var allFilesCache: [PublishedFile] = []
    
    private var limitFolder: Int = 20
    private var offsetFolder: Int = 0
    private var isLoadingFolder: Bool = false
    private var folderFilesLoaded: Bool = false
    private var folderFilesCache: [PublishedFile] = []
    
    private var currentFolderPath: String = ""
    
    init(view: FilesView, oAuthToken: String, apiService: APIService) {
        self.view = view
        self.oAuthToken = oAuthToken
        self.apiService = apiService
    }
    
    func fetchAllFiles(path: String = "disk:/", limit: Int = 20, offset: Int = 0, baseURL: String = APIEndpoint.resources.url, sort: String = "created") {
        offsetAll = 0
        allFilesLoaded = false
        allFilesCache = []
        limitAll = limit

        getAllFiles(path: path, limit: limitAll, offset: offsetAll, baseURL: baseURL, sort: sort)
    }
    

    func loadNextPageAllFilesIfNeeded(path: String = "disk:/", baseURL: String = APIEndpoint.resources.url, sort: String = "created") {
        guard !isLoadingAll, !allFilesLoaded else { return }
        offsetAll += limitAll
        getAllFiles(path: path, limit: limitAll, offset: offsetAll, baseURL: baseURL, sort: sort)
    }

    private func getAllFiles(path: String, limit: Int, offset: Int, baseURL: String, sort: String) {
        isLoadingAll = true
        view?.showLoading()
        
        apiService.fetchAllFilesAndFolders(oAuthToken: oAuthToken, baseURL: baseURL, path: path, limit: limit, offset: offset, sort: sort) { result in
            DispatchQueue.main.async {
                self.view?.hideLoading()
                self.isLoadingAll = false
            }
            
            switch result {
            case .success(let fetchedFiles):
                if !fetchedFiles.isEmpty {
                    CoreDataManager.shared.savePublishedFiles(fetchedFiles, for: "AllFilesViewController")
                    self.allFilesCache.append(contentsOf: fetchedFiles)
                    if fetchedFiles.count < limit {
                        self.allFilesLoaded = true
                    }
                    
                    DispatchQueue.main.async {
                        self.view?.showAllFiles(self.allFilesCache)
                    }
                } else {
                    self.allFilesLoaded = true
                    DispatchQueue.main.async {
                        self.view?.showAllFiles(self.allFilesCache)
                    }
                }
                
            case .failure(let error):
                let nsError = error as NSError
                DispatchQueue.main.async {
                    if nsError.code == NSURLErrorNotConnectedToInternet ||
                        nsError.code == NSURLErrorCannotFindHost {
                        self.view?.showNoInternetBanner(message: "No internet. Loading cache data.")
                        let cachedFiles = CoreDataManager.shared.fetchPublishedFiles(for: "AllFilesViewController")
                        self.allFilesCache = cachedFiles
                        self.view?.showAllFiles(self.allFilesCache)
                    } else {
                        self.view?.showAllFiles(self.allFilesCache)
                        self.view?.showError(error)
                    }
                }
            }
        }
    }
    
    func fetchFolderContents(path: String, limit: Int = 20, offset: Int = 0, baseURL: String = APIEndpoint.resources.url, previewSize: String = "120x120", previewCrop: String = "true") {
        currentFolderPath = path

        offsetFolder = 0
        folderFilesLoaded = false
        folderFilesCache = []
        limitFolder = limit
        
        getFolderContents(path: path, limit: limitFolder, offset: offsetFolder, baseURL: baseURL, previewSize: previewSize, previewCrop: previewCrop)
    }

    func loadNextPageFolderIfNeeded(baseURL: String = APIEndpoint.resources.url, previewSize: String = "120x120", previewCrop: String = "true") {
        guard !isLoadingFolder, !folderFilesLoaded else { return }
        offsetFolder += limitFolder
        getFolderContents(path: currentFolderPath, limit: limitFolder, offset: offsetFolder, baseURL: baseURL, previewSize: previewSize, previewCrop: previewCrop)
    }
   
    private func getFolderContents(path: String, limit: Int, offset: Int, baseURL: String, previewSize: String, previewCrop: String) {
        isLoadingFolder = true
        view?.showLoading()
        
        apiService.fetchFolderMetadata(oAuthToken: oAuthToken, baseURL: baseURL, path: path, limit: limit, offset: offset, previewSize: previewSize, previewCrop: previewCrop) { result in
            DispatchQueue.main.async {
                self.view?.hideLoading()
                self.isLoadingFolder = false
            }
            
            switch result {
            case .success(let fetchedFiles):
                if !fetchedFiles.isEmpty {
                   
                    self.folderFilesCache.append(contentsOf: fetchedFiles)
                    
                    if fetchedFiles.count < limit {
                        self.folderFilesLoaded = true
                    }
                    
                    DispatchQueue.main.async {
                        self.view?.showFolderData(self.folderFilesCache)
                    }
                } else {
                    self.folderFilesLoaded = true
                    DispatchQueue.main.async {
                        self.view?.showFolderData(self.folderFilesCache)
                    }
                }
                
            case .failure(let error):
                let nsError = error as NSError
                DispatchQueue.main.async {
                    if nsError.code == NSURLErrorNotConnectedToInternet ||
                        nsError.code == NSURLErrorCannotFindHost {
                        self.view?.showNoInternetBanner(message: "No internet. Loading cache data.")
                        self.view?.showFolderData(self.folderFilesCache)
                    } else {
                        self.view?.showFolderData(self.folderFilesCache)
                        self.view?.showError(error)
                    }
                }
            }
        }
    }
    
    func downloadFile(path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let fileName = (path as NSString).lastPathComponent
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: documentsURL.path) {
            DispatchQueue.main.async {
                completion(.success(documentsURL))
            }
            return
        }

        DispatchQueue.main.async {
            self.view?.showLoading()
        }
        
        apiService.fetchDownloadLink(oAuthToken: oAuthToken, path: path, baseURL: APIEndpoint.download.url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let downloadHref):
                self.apiService.downloadFile(oAuthToken: self.oAuthToken, from: downloadHref) { downloadResult in
                    DispatchQueue.main.async {
                        self.view?.hideLoading()
                    }
                    switch downloadResult {
                    case .success(let fileData):
                        DispatchQueue.global(qos: .utility).async {
                            do {
                                try fileData.write(to: documentsURL)
                                DispatchQueue.main.async {
                                    completion(.success(documentsURL))
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    completion(.failure(error))
                                }
                            }
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.view?.hideLoading()
                    completion(.failure(error))
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

