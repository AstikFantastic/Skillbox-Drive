import UIKit

protocol LoginViewProtocol: AnyObject {
    func navigateToTabBar()
}

class LoginPresenter {
    private weak var view: LoginViewProtocol?
    internal var router: LoginRouterProtocol
    
    init(view: LoginViewProtocol, router: LoginRouterProtocol) {
        self.view = view
        self.router = router
    }
    
    func handleLogin() {
        view?.navigateToTabBar()
    }
}
