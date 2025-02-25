import UIKit


class Router {
    
    private weak var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func navigateToFileDetail(with item: PublishedFile) {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else { return }
        let imagePresenter = ImagePresenter(item: item, oAuthToken: token, apiService: APIService())
        let imageViewController = ImageViewController(presenter: imagePresenter, item: item)
        navigationController?.pushViewController(imageViewController, animated: true)
    }
    
    func navigateToPDFDetail(with item: PublishedFile) {
        guard let filePath = item.file, let fileURL = URL(string: filePath) else {
            return
        }
        let pdfPage = PDFModel(name: item.name, fileURL: fileURL)
        let pdfPresenter = PDFPresenter(item: item, pdfFile: pdfPage)
        let pdfViewController = PDFViewController(presenter: pdfPresenter, item: item)
        navigationController?.pushViewController(pdfViewController, animated: true)
    }
    
    func navigateToWebPage(with item: PublishedFile) {
        guard let filePath = item.file, let fileURL = URL(string: filePath) else {
            return
        }
        let webPage = OfficeModel(name: item.name, url: fileURL)
        let presenter = OfficePresenter(item: item, page: webPage)
        let webViewController = OfficeViewController(presenter: presenter, item: item)
        navigationController?.pushViewController(webViewController, animated: true)
    }
    
    func navigateToLoginScreen() {
        let loginVC = LoginViewController()
        let navController = UINavigationController(rootViewController: loginVC)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = navController
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        }
    }
    
    func navigeteToPublishedFiles() {
        let vc = PublishedFilesViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func returnToProfileVC() {
        navigationController?.popViewController(animated: true)
    }
}
