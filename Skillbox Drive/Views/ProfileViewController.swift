import UIKit

protocol ProfileViewProtocol: AnyObject {
    func showLogoutAlert()
    func showDiskData(_ diskData: ProfileModel)
    func showError(_ error: Error)
}

class ProfileViewController: UIViewController, ProfileViewProtocol {
    
    var presenter: ProfilePresenter!
    private let progressLayer = CAShapeLayer()
    private var circlePath: UIBezierPath!
    private var totalSpaceLabel = UILabel()
    private var usedSpace = UILabel()
    private var usedSpaceCircle = UIView()
    private var availableSpace = UILabel()
    private var availableSpaceCircle = UIView()
    private var vStackSpace = UIStackView()
    private var hStackUsedSpace = UIStackView()
    private var hStackAvailableSpace = UIStackView()
    private var publishedFilesButton = UIButton()
    private let arrowImage = UIImageView()
    private var usedLayer: CAShapeLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if let oAuthToken = UserDefaults.standard.string(forKey: "userToken") {
            let router = Router(navigationController: navigationController!)
            presenter = ProfilePresenter(view: self, oAuthToken: oAuthToken, router: router)
            presenter.fetchDiskData()
        }
    }
    
    private func setupUI() {
        title = "Profile"
        let backButton = UIBarButtonItem()
        backButton.title = ""
        navigationItem.backBarButtonItem = backButton
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(didTapMoreButton)
        )
        
        setupCircleProgress()
        totalSpaceLabel.font = UIFont.boldSystemFont(ofSize: 16)
        totalSpaceLabel.textColor = UIColor.darkGray
        totalSpaceLabel.textAlignment = .center
        totalSpaceLabel.text = "-- GB"
        usedSpace.text = "-- GB - used"
        usedSpace.textAlignment = .left
        usedSpaceCircle.backgroundColor = UIColor(cgColor: CGColor(red: 241/255, green: 175/255, blue: 171/255, alpha: 1))
        usedSpaceCircle.layer.cornerRadius = 10
        hStackUsedSpace = UIStackView(arrangedSubviews: [usedSpaceCircle, usedSpace])
        hStackUsedSpace.axis = .horizontal
        hStackUsedSpace.spacing = 10
        availableSpace.text = "-- GB - available"
        availableSpace.textAlignment = .left
        availableSpaceCircle.backgroundColor = UIColor(cgColor: CGColor(red: 158/255, green: 158/255, blue: 158/255, alpha: 1))
        availableSpaceCircle.layer.cornerRadius = 10
        hStackAvailableSpace = UIStackView(arrangedSubviews: [availableSpaceCircle, availableSpace])
        hStackAvailableSpace.axis = .horizontal
        hStackAvailableSpace.spacing = 10
        vStackSpace = UIStackView(arrangedSubviews: [hStackUsedSpace, hStackAvailableSpace])
        vStackSpace.axis = .vertical
        vStackSpace.spacing = 20
        publishedFilesButton.setTitle("Published files", for: .normal)
        publishedFilesButton.setTitleColor(.black, for: .normal)
        publishedFilesButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        publishedFilesButton.contentHorizontalAlignment = .left
        publishedFilesButton.layer.borderWidth = 0.33
        publishedFilesButton.layer.borderColor = UIColor.lightGray.cgColor
        publishedFilesButton.layer.cornerRadius = 10
        publishedFilesButton.backgroundColor = .white // Белый фон
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 17.5, bottom: 0, trailing: 0)
        publishedFilesButton.configuration = config
        publishedFilesButton.addTarget(self, action: #selector(showPublishedFiles), for: .touchUpInside)
        arrowImage.image = UIImage(systemName: "chevron.right")
        arrowImage.tintColor = .gray
        publishedFilesButton.layer.shadowColor = UIColor.black.cgColor
        publishedFilesButton.layer.shadowOpacity = 0.1
        publishedFilesButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        publishedFilesButton.layer.shadowRadius = 4
        
        view.addSubview(totalSpaceLabel)
        view.addSubview(vStackSpace)
        publishedFilesButton.addSubview(arrowImage)
        view.addSubview(publishedFilesButton)
        
        totalSpaceLabel.translatesAutoresizingMaskIntoConstraints = false
        vStackSpace.translatesAutoresizingMaskIntoConstraints = false
        arrowImage.translatesAutoresizingMaskIntoConstraints = false
        publishedFilesButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            totalSpaceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            totalSpaceLabel.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 250),
            usedSpaceCircle.widthAnchor.constraint(equalToConstant: 20),
            usedSpaceCircle.heightAnchor.constraint(equalToConstant: 20),
            availableSpaceCircle.widthAnchor.constraint(equalToConstant: 20),
            availableSpaceCircle.heightAnchor.constraint(equalToConstant: 20),
            vStackSpace.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            vStackSpace.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 352),
            arrowImage.centerYAnchor.constraint(equalTo: publishedFilesButton.centerYAnchor),
            arrowImage.trailingAnchor.constraint(equalTo: publishedFilesButton.trailingAnchor, constant: -16),
            publishedFilesButton.heightAnchor.constraint(equalToConstant: 45),
            publishedFilesButton.topAnchor.constraint(equalTo: vStackSpace.bottomAnchor, constant: 20),
            publishedFilesButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 17.5),
            publishedFilesButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -17.5),
        ])
    }
    
    func showDiskData(_ diskData: ProfileModel) {
        let usedSpacePercentage = presenter.calculateUsedPercentage(diskData: diskData)
        let totalSpace = presenter.formatBtToGb(Int64(diskData.totalSpace))
        let usedSpace = presenter.formatBtToGb(Int64(diskData.usedSpace))
        let availableSpace = presenter.findAvailableSpace(diskData: diskData)
        
        DispatchQueue.main.async {
            self.totalSpaceLabel.text = "\(totalSpace) GB"
            self.usedSpace.text = "\(usedSpace) GB - used"
            self.availableSpace.text = "\(availableSpace) GB - available"
        }
        
        DispatchQueue.main.async {
            self.animateCircleProgress(usedPercentage: usedSpacePercentage)
        }
    }
    
    @objc func didTapMoreButton() {
        presenter.didTapMoreButton()
    }
    
    func showLogoutAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let titleAction = UIAlertAction(title: "Profile", style: .default, handler: nil)
        titleAction.setValue(UIColor.lightGray, forKey: "titleTextColor")
        let deleteAction = UIAlertAction(title: "Log Out", style: .destructive) { _ in
            self.showLogoutConfirmation()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(titleAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        if let firstAction = alert.actions.first {
            firstAction.isEnabled = false
        }
        present(alert, animated: true)
    }

    private func showLogoutConfirmation() {
        let alert = UIAlertController(title: "Exit", message: "Are you sure you want to log out? All data will be deleted.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            self.presenter.logout()
            CoreDataManager.shared.clearCache()
            ImageCacheManager.shared.clearCache()
        }
        let cancelAction = UIAlertAction(title: "No", style: .cancel)
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    private func setupCircleProgress() {
        let radius: CGFloat = 105.5
        let center = CGPoint(x: view.center.x, y: 250)
        circlePath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -CGFloat.pi / 2,
            endAngle: 2 * CGFloat.pi - CGFloat.pi / 2,
            clockwise: true
        )
        
        DispatchQueue.main.async {
            self.progressLayer.path = self.circlePath.cgPath
            self.progressLayer.strokeColor = CGColor(red: 158/255, green: 158/255, blue: 158/255, alpha: 1)
            self.progressLayer.fillColor = UIColor.clear.cgColor
            self.progressLayer.lineWidth = 40
            self.progressLayer.lineCap = .butt
            self.view.layer.addSublayer(self.progressLayer)
            if self.usedLayer == nil {
                self.usedLayer = CAShapeLayer()
                self.usedLayer.path = self.circlePath.cgPath
                self.usedLayer.strokeColor = CGColor(red: 241/255, green: 175/255, blue: 171/255, alpha: 1)
                self.usedLayer.fillColor = UIColor.clear.cgColor
                self.usedLayer.lineWidth = 40
                self.usedLayer.lineCap = .butt
                self.usedLayer.strokeEnd = 0
                self.view.layer.addSublayer(self.usedLayer)
            }
        }
    }
    
    private func animateCircleProgress(usedPercentage: CGFloat) {
        let usedAnimation = CABasicAnimation(keyPath: "strokeEnd")
        usedAnimation.toValue = usedPercentage
        usedAnimation.duration = 1.0
        usedAnimation.fillMode = .forwards
        usedAnimation.isRemovedOnCompletion = false
        self.usedLayer.add(usedAnimation, forKey: "usedProgress")
    }
    
    @objc private func showPublishedFiles() {
        presenter.toPublishedFiles()
        print("Кнопка нажата")
    }
    
    func showError(_ error: Error) {
        print("Error: \(error.localizedDescription)")
    }
}
