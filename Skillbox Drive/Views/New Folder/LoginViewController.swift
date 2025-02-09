import UIKit
import YandexLoginSDK

class LoginViewController: UIViewController, LoginViewProtocol, YandexLoginSDKObserver {
    
    private var logoImage = UIImageView()
    private let button = UIButton()
    private var presenter: LoginPresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        let router = LoginRouter()
        presenter = LoginPresenter(view: self, router: router)
        
        do {
            try YandexLoginSDK.shared.activate(with: "537838d5d9a1441687edd5d18255c8e6", authorizationStrategy: .webOnly)
            YandexLoginSDK.shared.add(observer: self)
            
        } catch {
            print("Ошибка активации YandexLoginSDK: \(error.localizedDescription)")
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        logoImage.image = UIImage(named: "лого")
        logoImage.contentMode = .scaleAspectFill
        
        button.setTitle("Войти", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "Graphik", size: 16)
        button.backgroundColor = UIColor(red: 56/255, green: 63/255, blue: 245/255, alpha: 1)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        view.addSubview(logoImage)
        view.addSubview(button)
    }
    
    @objc func loginButtonTapped() {
        do {
            try YandexLoginSDK.shared.authorize(with: YandexIdWebViewController(), customValues: nil, authorizationStrategy: .webOnly)
        } catch {
            print("Ошибка при запуске авторизации: \(error.localizedDescription)")
        }
    }
    
    func didFinishLogin(with result: Result<LoginResult, Error>) {
        switch result {
        case .success(let loginResult):
            UserDefaults.standard.set(loginResult.token, forKey: "userToken")
            print("Успешная авторизация, токен сохранен: \(loginResult.token)")
            navigateToTabBar()
        case .failure(let error):
            print("Ошибка авторизации: \(error.localizedDescription)")
        }
    }
    
    func logOut() {
        do {
            try YandexLoginSDK.shared.logout()
            UserDefaults.standard.removeObject(forKey: "userToken")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func navigateToTabBar() {
        presenter.router.navigateToTabBar(from: self)
    }
}

extension LoginViewController {
    private func setupConstraints() {
        logoImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logoImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 271.05),
            logoImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 90),
            logoImage.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -90),
            logoImage.heightAnchor.constraint(equalToConstant: 168)
        ])
        
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.topAnchor, constant: 670),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 27),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -27),
            button.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
}
