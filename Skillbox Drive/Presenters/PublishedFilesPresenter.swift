import Foundation
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
    
    var errorFiles: Error?
    var errorDirs: Error?
    
    private var limitPublished: Int = 20
    private var offsetPublished: Int = 0
    private var isLoadingPublished: Bool = false
    private var allPublishedLoaded: Bool = false

    private var publishedItems: [PublishedFile] = []
    
    private var limitFolder: Int = 20
    private var offsetFolder: Int = 0
    private var isLoadingFolder: Bool = false
    private var allFolderLoaded: Bool = false
    
    private var folderItems: [PublishedFile] = []
    
    private var currentFolderPath: String = ""
    
    init(view: PublishedFilesView, oAuthToken: String, apiService: APIService) {
        self.view = view
        self.oAuthToken = oAuthToken
        self.apiService = apiService
    }
    
    func fetchPublishedFiles(limit: Int = 20, offset: Int = 0, baseURL: String = APIEndpoint.publicResources.url) {
        if offset == 0 {
            offsetPublished = 0
            allPublishedLoaded = false
            publishedItems = []
            errorFiles = nil
            errorDirs = nil
        }
        
        if isLoadingPublished || allPublishedLoaded {
            return
        }
        
        limitPublished = limit
        offsetPublished = offset
        isLoadingPublished = true
        
        view?.showLoading()
        
        let dispatchGroup = DispatchGroup()
        var fetchedFiles: [PublishedFile] = []
        var fetchedDirs: [PublishedFile] = []
        
        dispatchGroup.enter()
        apiService.fetchFiles(oAuthToken: oAuthToken, baseURL: baseURL, limit: limit, offset: offset) { result in
            switch result {
            case .success(let files):
                fetchedFiles = files
            case .failure(let error):
                self.errorFiles = error
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        apiService.fetchDirs(oAuthToken: oAuthToken, baseURL: baseURL, limit: limit, offset: offset) { result in
            switch result {
            case .success(let dirs):
                fetchedDirs = dirs
            case .failure(let error):
                self.errorDirs = error
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.isLoadingPublished = false
            self.view?.hideLoading()
            
            let allItems = fetchedDirs + fetchedFiles
            
            if !allItems.isEmpty {
                if allItems.count < limit {
                    self.allPublishedLoaded = true
                }
                
                self.publishedItems.append(contentsOf: allItems)
                
                CoreDataManager.shared.savePublishedFiles(allItems, for: "PublishedFilesViewController")
                
                self.view?.showAllFiles(self.publishedItems)
            }
            else {
                if let error = self.errorFiles ?? self.errorDirs,
                   ((error as NSError).code == NSURLErrorNotConnectedToInternet ||
                    (error as NSError).code == NSURLErrorCannotFindHost) {
                    self.view?.showNoInternetBanner(message: "No internet. Loading cache data.")
                    let cachedFiles = CoreDataManager.shared.fetchPublishedFiles(for: "PublishedFilesViewController")
                    self.publishedItems = cachedFiles
                    self.view?.showAllFiles(cachedFiles)
                } else {
                    self.view?.showAllFiles([])
                }
            }
        }
    }
    
    func loadNextPagePublishedIfNeeded() {
        guard !isLoadingPublished, !allPublishedLoaded else { return }
        
        offsetPublished += limitPublished
        
        fetchPublishedFiles(limit: limitPublished, offset: offsetPublished)
    }
  
    func fetchFolderContents(path: String, limit: Int = 20, offset: Int = 0, baseURL: String = APIEndpoint.resources.url, previewSize: String = "120x120",
    previewCrop: String = "true") {
        if offset == 0 {
            offsetFolder = 0
            allFolderLoaded = false
            folderItems = []
            currentFolderPath = path
        }
        
        if isLoadingFolder || allFolderLoaded {
            return
        }
        
        limitFolder = limit
        offsetFolder = offset
        isLoadingFolder = true
        
        view?.showLoading()
        print("Fetching contents for folder at path: \(path), offset=\(offset)")
        
        apiService.fetchFolderMetadata(oAuthToken: oAuthToken, baseURL: baseURL, path: path, limit: limit, offset: offset, previewSize: previewSize, previewCrop: previewCrop) { result in
            DispatchQueue.main.async {
                self.isLoadingFolder = false
                self.view?.hideLoading()
            }
            
            switch result {
            case .success(let fetchedFiles):
                print("Successfully fetched folder contents (count=\(fetchedFiles.count)): \(fetchedFiles)")
                
                if fetchedFiles.count < limit && fetchedFiles.count > 0 {
                    self.allFolderLoaded = true
                }
                
                if fetchedFiles.isEmpty {
                    DispatchQueue.main.async {
                        self.view?.showFolderData(self.folderItems)
                    }
                } else {
                    self.folderItems.append(contentsOf: fetchedFiles)
                    DispatchQueue.main.async {
                        self.view?.showFolderData(self.folderItems)
                    }
                }
                
            case .failure(let error):
                print("Error fetching folder contents: \(error)")
                DispatchQueue.main.async {
                    self.view?.showError(error)
                }
            }
        }
    }
    
    func loadNextPageFolderIfNeeded() {
        guard !isLoadingFolder, !allFolderLoaded else { return }
        
        offsetFolder += limitFolder
        fetchFolderContents(path: currentFolderPath, limit: limitFolder, offset: offsetFolder)
    }
    
    func unpublishRespopnse(path: String) {
        apiService.unpublishResource(oAuthToken: oAuthToken, baseURL: APIEndpoint.unpublish.url, path: path) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.offsetPublished = 0
                    self.allPublishedLoaded = false
                    self.publishedItems.removeAll()
                    
                    self.fetchPublishedFiles(limit: self.limitPublished, offset: self.offsetPublished)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.view?.showError(error)
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
