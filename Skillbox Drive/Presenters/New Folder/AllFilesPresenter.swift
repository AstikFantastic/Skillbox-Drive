import UIKit

protocol FilesView: AnyObject {
    func showLoading()
    func hideLoading()
    func showAllFiles(_ files: [Item])
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
    
    func fetchAllFiles(limit: Int = 10, offset: Int = 0) {
        view?.showLoading()
        apiService.fetchAllFiles(oAuthToken: oAuthToken, limit: limit, offset: offset) { [weak self] result in
            self?.view?.hideLoading()
            switch result {
            case .success(let data):
                self?.view?.showAllFiles(data.items)
            case .failure(let error):
                self?.view?.showError(error)
            }
        }
    }
    
    func formatBtToMb(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_048_576
        if mb.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", mb)
        } else {
            return String(format: "%.2f", mb)
        }
    }
    
    func formattedFileSize(from size: Int?) -> String {
        guard let size = size else { return "Unknown size" }
        return "\(size / 1_048_576) mb"
    }
    
    func formattedCreationDate(from createdString: String?) -> String {
        guard let createdString = createdString,
              let createdDate = DateFormatter.date(from: createdString) else {
            return "Unknown date"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: createdDate)
    }
}

private extension DateFormatter {
    static func date(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: string)
    }
}
