import UIKit

class ImageViewController: UIViewController, FileDetailView {
    
    var item: PublishedFile
    private let presenter: ImagePresenter
    private let imageView = UIImageView()
    private let linkButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    
    var isFullScreen = false
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    init(presenter: ImagePresenter, item: PublishedFile) {
        self.presenter = presenter
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
            presenter.attachView(self)
            presenter.loadImage()
            presenter.updateNavigationBar()
        
        setupUI()

        imageView.isUserInteractionEnabled = true
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTapGesture)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        imageView.addGestureRecognizer(panGestureRecognizer)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        tabBarController?.isTabBarHidden = false
    }
    
    
    private func setupUI() {
        view.backgroundColor = .white
        
        let backNavButton = UIBarButtonItem(image: UIImage(systemName: "rectangle.and.pencil.and.ellipsis"), style: .plain, target: self, action: #selector(renameButtonTapped))
        navigationItem.rightBarButtonItem = backNavButton
        
        tabBarController?.isTabBarHidden = true
        
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear
        
        linkButton.setImage(UIImage(named: "link"), for: .normal)
        linkButton.tintColor = .black
        linkButton.translatesAutoresizingMaskIntoConstraints = false
        linkButton.addTarget(self, action: #selector(shareFoto), for: .touchUpInside)
        
        deleteButton.setImage(UIImage(named: "trash"), for: .normal)
        deleteButton.tintColor = .red
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteFile), for: .touchUpInside)
        
        view.addSubview(imageView)
        view.addSubview(linkButton)
        view.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            linkButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            linkButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 54),
            
            deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -54)
        ])
    }
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        
        if isFullScreen {
            UIView.animate(withDuration: 0.3, animations: {
                self.imageView.transform = CGAffineTransform.identity
                self.imageView.center = self.view.center
                print("Нормальное состояние")
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                let scaleX = self.view.bounds.width / self.imageView.frame.width * 2
                let scaleY = self.view.bounds.height / self.imageView.frame.height * 2
                let scale = max(scaleX, scaleY)
                
                self.imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
                
                self.imageView.center = self.view.center
                
                print("Не нормальное состояние")
            })
        }
        
        isFullScreen.toggle()
    }
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {

        guard isFullScreen else { return }
        
        let translation = gesture.translation(in: view)
        
        if gesture.state == .changed {
            imageView.center = CGPoint(x: imageView.center.x + translation.x, y: imageView.center.y + translation.y)
            
            gesture.setTranslation(.zero, in: view)
        }
    }
    
    @objc func renameButtonTapped() {
        
        let renameVC = RenameViewController()
        renameVC.currentName = item.name ?? ""
        
        renameVC.onRename = { [weak self] newName in
            guard let self = self else { return }

            renameVC.hidesBottomBarWhenPushed = true
            self.presenter.renameFile(newName: newName)
        }
        
        navigationController?.pushViewController(renameVC, animated: true)
    }
    
    func updateNavigationBar() {
        let stackView = createNavigationTitleStack(name: item.name, creationDate: item.created)
        navigationItem.titleView = stackView
    }
    
    func displayImage(image: UIImage?) {
        imageView.image = image ?? UIImage(systemName: "photo")
    }
    
    @objc private func shareFoto() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let shareFileAction = UIAlertAction(title: "Поделиться файлом", style: .default) { _ in
                guard let image = self.imageView.image else { return }
                guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                    return
                }
                let fileName = self.item.name
                
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName ?? "")
                
                do {
                    try imageData.write(to: tempURL)
                    let activityController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                    self.present(activityController, animated: true, completion: nil)
                } catch {
                    print("Ошибка при записи файла:", error)
                }
            }
        
        let shareLinkAction = UIAlertAction(title: "Поделиться ссылкой", style: .default) { [self] _ in
                    presenter.publishResource { [weak self] publishResult in
                        guard let self = self else { return }
                        switch publishResult {
                        case .success:
                            self.presenter.fetchPublicURL { fetchResult in
                                DispatchQueue.main.async {
                                    switch fetchResult {
                                    case .success(let publicLink):
                                        let activityController = UIActivityViewController(activityItems: [publicLink], applicationActivities: nil)
                                        self.present(activityController, animated: true, completion: nil)
                                    case .failure(let error):
                                        let alert = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                                        self.present(alert, animated: true)
                                    }
                                }
                            }
                        case .failure(let error):
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .default))
                                self.present(alert, animated: true)
                            }
                        }
                    }
                }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        
        alert.addAction(shareFileAction)
        alert.addAction(shareLinkAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }

    
    @objc private func deleteFile() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let titleAction = UIAlertAction(title: "Current image will be deleted", style: .default, handler: nil)
        titleAction.setValue(UIColor.lightGray, forKey: "titleTextColor")
        let deleteAction = UIAlertAction(title: "Delete image", style: .destructive) { _ in
            self.presenter.deleteFile(permanently: "true", path: self.item.path ?? "")
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
    
}



