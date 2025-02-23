import UIKit

protocol LastFilesView: AnyObject {
    func showLoading()
    func hideLoading()
    func showAllFiles(_ files: [PublishedFile])
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
    
    func fetchLastLoadedFiles(limit: Int = 100, offset: Int = 0, previewSize: String = "25x22", previewCrop: String = "true") {
        view?.showLoading()
        apiService.fetchLastLoadedFiles(oAuthToken: oAuthToken, limit: limit, offset: offset, previewSize: previewSize, previewCrop: previewCrop) { [weak self] result in
            self?.view?.hideLoading()
            switch result {
            case .success(let data):
                self?.view?.showAllFiles(data)
            case .failure(let error):
                self?.view?.showError(error)
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
