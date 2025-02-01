import UIKit

protocol ImageViewProtocol: AnyObject {
    func updateFrame(_ frame: CGRect)
}

class ImageViewController: UIViewController, FileDetailView, ImageViewProtocol {
    
    private let presenter: ImagePresenter
    private let imageView = UIImageView()
    private let linkButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    
    init(presenter: ImagePresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        presenter.attachView(self)
        presenter.loadFileDetails()
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTapGesture)
        imageView.isUserInteractionEnabled = true
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear
        
        linkButton.setImage(UIImage(named: "link"), for: .normal)
        linkButton.tintColor = .black
        linkButton.translatesAutoresizingMaskIntoConstraints = false
        linkButton.addTarget(self, action: #selector(editFile), for: .touchUpInside)
        
        deleteButton.setImage(UIImage(named: "trash"), for: .normal)
        deleteButton.tintColor = .black
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteFile), for: .touchUpInside)
        
        view.addSubview(imageView)
        view.addSubview(linkButton)
        view.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 1),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 1),
            imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            linkButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            linkButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 54),
            
            deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -54)
        ])
    }
    
    @objc func handleDoubleTap() {
        presenter.onImagetapped()
    }
    
    func updateFrame(_ frame: CGRect) {
        UIView.animate(withDuration: 0.3) {
            self.imageView.frame = frame
        }
    }
    
    func displayFileDetails(name: String, creationDate: String, previewImage: UIImage?) {
        let titleLabel = UILabel()
        titleLabel.text = name
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        
        let dateLabel = UILabel()
        dateLabel.text = creationDate
        dateLabel.font = UIFont.systemFont(ofSize: 10)
        dateLabel.textColor = UIColor(red: 158/255, green: 158/255, blue: 158/255, alpha: 1)
        dateLabel.textAlignment = .center
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .center
        
        navigationItem.titleView = stackView
        
        imageView.image = previewImage ?? UIImage(systemName: "photo")
    }
    
    @objc private func editFile() {
        print("Edit button tapped.")
    }
    
    @objc private func deleteFile() {
        print("Delete button tapped.")
    }
}
