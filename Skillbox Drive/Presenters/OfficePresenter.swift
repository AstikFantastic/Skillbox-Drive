import UIKit

protocol OfficeView: AnyObject {
    func loadURL(_ url: URL)
    func showError(message: String)
}

class OfficePresenter {
    let item: Items
    private let page: OfficeModel
    private weak var view: OfficeView?
    
    init(item: Items, page: OfficeModel) {
        self.item = item
        self.page = page
    }
    
    func attachView(_ view: OfficeView) {
        self.view = view
    }
    
    func loadPage() {
        guard let url = URL(string: page.url.absoluteString) else {
            view?.showError(message: "Invalid URL")
            return
        }
        view?.loadURL(url)
    }
    
    func updateNavigationBar() {
        if let viewController = view as? UIViewController {
            let stackView = viewController.createNavigationTitleStack(name: item.name, creationDate: item.created)
            viewController.navigationItem.titleView = stackView
        }
    }
}
