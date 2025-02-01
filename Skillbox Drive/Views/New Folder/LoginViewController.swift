import UIKit

class LoginViewController: UIViewController, LoginViewProtocol {
    
    private var logoImage = UIImageView()
    private let button = UIButton()
    private var presenter: LoginPresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()        
        let router = LoginRouter()
        presenter = LoginPresenter(view: self, router: router)
    }

    private func setupUI() {
        
        view.backgroundColor = .white
        logoImage.image = UIImage(named: "лого") ?? nil
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
        presenter.handleLogin()
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
