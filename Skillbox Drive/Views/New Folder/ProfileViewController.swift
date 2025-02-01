import UIKit

class ProfileViewController: UIViewController, ProfileView {
    
    var presenter: ProfilePresenter!
    
    let oAuthToken = "y0__wgBEOyZ3QoY95k0IKXpv_gRIYdzi_pi2qSwvmQGmILMWrnnk04"
    
    
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
        presenter = ProfilePresenter(view: self, oAuthToken: oAuthToken)
        presenter.fetchDiskData()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        setupCircleProgress()
        
        totalSpaceLabel.font = UIFont.boldSystemFont(ofSize: 16)
        totalSpaceLabel.textColor = UIColor.darkGray
        totalSpaceLabel.textAlignment = .center
        totalSpaceLabel.text = "-- GB"
        view.addSubview(totalSpaceLabel)
        totalSpaceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            totalSpaceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            totalSpaceLabel.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 250)
        ])
        
        usedSpace.text = "-- GB - used"
        usedSpace.textAlignment = .left
        
        usedSpaceCircle.backgroundColor = UIColor(cgColor: CGColor(red: 241/255, green: 175/255, blue: 171/255, alpha: 1))
        usedSpaceCircle.layer.cornerRadius = 10
        NSLayoutConstraint.activate([
            usedSpaceCircle.widthAnchor.constraint(equalToConstant: 20),
            usedSpaceCircle.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        hStackUsedSpace = UIStackView(arrangedSubviews: [usedSpaceCircle, usedSpace])
        hStackUsedSpace.axis = .horizontal
        hStackUsedSpace.spacing = 10
        
        availableSpace.text = "-- GB - available"
        availableSpace.textAlignment = .left
        
        availableSpaceCircle.backgroundColor = UIColor(cgColor: CGColor(red: 158/255, green: 158/255, blue: 158/255, alpha: 1))
        availableSpaceCircle.layer.cornerRadius = 10
        NSLayoutConstraint.activate([
            availableSpaceCircle.widthAnchor.constraint(equalToConstant: 20),
            availableSpaceCircle.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        hStackAvailableSpace = UIStackView(arrangedSubviews: [availableSpaceCircle, availableSpace])
        hStackAvailableSpace.axis = .horizontal
        hStackAvailableSpace.spacing = 10
        
        vStackSpace = UIStackView(arrangedSubviews: [hStackUsedSpace, hStackAvailableSpace])
        vStackSpace.axis = .vertical
        vStackSpace.spacing = 20
        view.addSubview(vStackSpace)
        vStackSpace.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vStackSpace.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            vStackSpace.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 352),
        ])
        
        publishedFilesButton.setTitle("Published files", for: .normal)
        publishedFilesButton.setTitleColor(.black, for: .normal)
        publishedFilesButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        publishedFilesButton.contentHorizontalAlignment = .left // Текст слева
        publishedFilesButton.layer.borderWidth = 0.33 // Граница
        publishedFilesButton.layer.borderColor = UIColor.lightGray.cgColor // Синий цвет границы
        publishedFilesButton.layer.cornerRadius = 10 // Закругленные углы
        publishedFilesButton.backgroundColor = .white // Белый фон
        publishedFilesButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 17.5, bottom: 0, right: 0)
        publishedFilesButton.addTarget(self, action: #selector(showPublishedFiles), for: .touchUpInside)
        
        arrowImage.image = UIImage(systemName: "chevron.right")
        arrowImage.tintColor = .gray
        publishedFilesButton.addSubview(arrowImage)
        arrowImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            arrowImage.centerYAnchor.constraint(equalTo: publishedFilesButton.centerYAnchor),
            arrowImage.trailingAnchor.constraint(equalTo: publishedFilesButton.trailingAnchor, constant: -16)
               ])
        
        view.addSubview(publishedFilesButton)
        publishedFilesButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            publishedFilesButton.heightAnchor.constraint(equalToConstant: 45),
            publishedFilesButton.topAnchor.constraint(equalTo: vStackSpace.bottomAnchor, constant: 20),
            publishedFilesButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 17.5),
            publishedFilesButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -17.5),
        ])
        
        publishedFilesButton.layer.shadowColor = UIColor.black.cgColor // Черный цвет тени
        publishedFilesButton.layer.shadowOpacity = 0.1 // Прозрачность тени
        publishedFilesButton.layer.shadowOffset = CGSize(width: 0, height: 2) // Смещение вниз
        publishedFilesButton.layer.shadowRadius = 4 // Радиус размытия
        
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
    
    @objc private func showPublishedFiles() {}
    
    func showError(_ error: Error) {
        print("Error: \(error.localizedDescription)")
    }
}
