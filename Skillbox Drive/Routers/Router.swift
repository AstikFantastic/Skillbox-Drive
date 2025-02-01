import UIKit

class Router {
    private weak var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func navigateToFileDetail(with item: Items) {
        let imagePresenter = ImagePresenter(item: item, apiService: APIService())
        let imageViewController = ImageViewController(presenter: imagePresenter)
        navigationController?.pushViewController(imageViewController, animated: true)
    }
    
    func navigateToPDFDetail(with item: Items) {
        guard let filePath = item.file, let fileURL = URL(string: filePath) else {
            return
        }
        let pdfItem = PDFModel(name: item.name, fileURL: fileURL)
        let pdfPresenter = PDFPresenter(item: pdfItem)
        let pdfViewController = PDFViewController(presenter: pdfPresenter)
        navigationController?.pushViewController(pdfViewController, animated: true)
    }
    
    func navigateToWebPage(with item: Items) {
        guard let filePath = item.file, let fileURL = URL(string: filePath) else {
            return
        }
        let webPage = OfficeModel(name: item.name, url: fileURL)
        let presenter = OfficePresenter(item: item, page: webPage)
        let webViewController = OfficeViewController(presenter: presenter)
        navigationController?.pushViewController(webViewController, animated: true)
    }
}
