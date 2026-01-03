import UIKit

protocol LastFilesView: AnyObject {
    func showLoading()
    func hideLoading()
    func showAllFiles(_ files: [PublishedFile])
    func showError(_ error: Error)
    func showNoInternetBanner(message: String)
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
        
        apiService.fetchFiles(oAuthToken: oAuthToken, baseURL: baseURL, limit: limit, offset: offset) { result in
            DispatchQueue.main.async {
                self.view?.hideLoading()
                
                switch result {
                case .success(let fetchedFiles):
                    if !fetchedFiles.isEmpty {
                        CoreDataManager.shared.savePublishedFiles(fetchedFiles, for: "LastFilesViewController")
                        self.view?.showAllFiles(fetchedFiles)
                    } else {
                        self.view?.showAllFiles([])
                    }
                    
                case .failure(let error):
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorNotConnectedToInternet ||
                       nsError.code == NSURLErrorCannotFindHost {
                        self.view?.showNoInternetBanner(message: "No internet. Loading cache data.")
                        let cachedFiles = CoreDataManager.shared.fetchPublishedFiles(for: "LastFilesViewController")
                        self.view?.showAllFiles(cachedFiles)
                    } else {
                        self.view?.showAllFiles([])
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
        } else if mb >= 1 && mb < 1024 {
            return String(format: "%.2f MB", mb)
        } else {
            let gb = mb / 1024
            return String(format: "%.2f GB", gb)
        }
    }
}
