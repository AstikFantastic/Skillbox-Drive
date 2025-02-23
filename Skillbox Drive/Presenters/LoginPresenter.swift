import UIKit
import YandexLoginSDK
import CoreData

protocol LoginViewProtocol: AnyObject {
    func navigateToTabBar()
    func yandexActivate()
    func yandexAutorizeRun()
    func didFinishLogin(with result: Result<LoginResult, Error>)
    func yandexLogout()
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
    
    func yandexActivate() {
        do {
            try YandexLoginSDK.shared.activate(with: "537838d5d9a1441687edd5d18255c8e6", authorizationStrategy: .webOnly)
            YandexLoginSDK.shared.add(observer: self)            
        } catch {
            print("Ошибка активации YandexLoginSDK: \(error.localizedDescription)")
        }
    }
    
    func yandexAutorizeRun() {
        do {
            try YandexLoginSDK.shared.authorize(with: YandexIdWebViewController(), customValues: nil, authorizationStrategy: .webOnly)
        } catch {
            print("Ошибка при запуске авторизации: \(error.localizedDescription)")
        }
    }
    
    func yandexLogout() {
        do {
            try YandexLoginSDK.shared.logout()
            print("YandexLogout выполнен успешно")
        } catch {
            print("Ошибка при логауте: \(error.localizedDescription)")
        }
    }
    
    func didFinishLogin(with result: Result<LoginResult, any Error>) {
        switch result {
        case .success(let loginResult):
            UserDefaults.standard.set(loginResult.token, forKey: "userToken")
            print("Успешная авторизация, токен сохранен: \(loginResult.token)")
            handleLogin()
        case .failure(let error):
            print("Ошибка авторизации: \(error.localizedDescription)")
        }
    }
    
}

extension LoginPresenter: YandexLoginSDKObserver {
    

}
