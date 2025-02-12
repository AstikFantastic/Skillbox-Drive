import UIKit
import YandexLoginSDK

protocol OnboardingView: AnyObject {
    func displayPage(image: UIImage, description: String, currentIndex: Int, totalPages: Int)
    func navigateToNextScreen()
}

class OnboardingViewController: UIViewController, OnboardingView {
    
    private var imageView = UIImageView()
    private var descriptionLabel = UILabel()
    private var nextButton = UIButton()
    private var pageControl = UIPageControl()
    
    var presenter: OnboardingPresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        presenter.viewDidLoad()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        imageView.contentMode = .scaleAspectFit
        descriptionLabel.font = UIFont(name: "Graphik", size: 17)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        nextButton.setTitle("Next", for: .normal)
        nextButton.layer.cornerRadius = 10
        nextButton.backgroundColor = UIColor(red: 56/255, green: 63/255, blue: 245/255, alpha: 1)
        nextButton.addTarget(self, action: #selector(didTapNextButton), for: .touchUpInside)
        pageControl.currentPageIndicatorTintColor = .blue
        pageControl.pageIndicatorTintColor = .lightGray
        [imageView, descriptionLabel, nextButton, pageControl].forEach{view.addSubview($0)}
    }
    
    @objc private func didTapNextButton() {
        presenter?.didTapNext()
    }
    
    func displayPage(image: UIImage, description: String, currentIndex: Int, totalPages: Int) {
        imageView.image = image
        descriptionLabel.text = description
        pageControl.currentPage = currentIndex
        pageControl.numberOfPages = totalPages
    }
    
    func navigateToNextScreen() {
        let mainVC = LoginViewController()
        navigationController?.setViewControllers([mainVC], animated: true)
    }
}

extension OnboardingViewController {
    private func setupConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 228),
            imageView.heightAnchor.constraint(equalToConstant: 147),
            imageView.widthAnchor.constraint(equalToConstant: 149),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 439),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 68),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -68),
            
            pageControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 620.12),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            nextButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 670),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 27.5),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -27.5),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
