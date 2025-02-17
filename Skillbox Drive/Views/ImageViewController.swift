import UIKit

protocol ImageViewProtocol: AnyObject {
    func updateFrame(_ frame: CGRect)
}

class ImageViewController: UIViewController, FileDetailView, ImageViewProtocol {
    
    private let item: Items
    private let presenter: ImagePresenter
    private let imageView = UIImageView()
    private let linkButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    
    var isFullScreen = false
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    init(presenter: ImagePresenter, item: Items) {
        self.presenter = presenter
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        presenter.attachView(self)
        presenter.loadImage()
        presenter.updateNavigationBar()
        
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
        tabBarController?.isTabBarHidden = true
        
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear
        
        linkButton.setImage(UIImage(named: "link"), for: .normal)
        linkButton.tintColor = .black
        linkButton.translatesAutoresizingMaskIntoConstraints = false
        linkButton.addTarget(self, action: #selector(shareFoto), for: .touchUpInside)
        
        deleteButton.setImage(UIImage(named: "trash"), for: .normal)
        deleteButton.tintColor = .black
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
            // Если изображение в полном экране, возвращаем его обратно
            UIView.animate(withDuration: 0.3, animations: {
                // Возвращаем изображение в исходный размер с сохранением пропорций
                self.imageView.transform = CGAffineTransform.identity
                // Позиционируем изображение обратно в центр
                self.imageView.center = self.view.center
                print("Нормальное состояние")
            })
        } else {
            // Если изображение не в полном экране, увеличиваем его так, чтобы оно выходило за пределы экрана
            UIView.animate(withDuration: 0.3, animations: {
                // Вычисляем масштаб, чтобы изображение стало больше экрана
                let scaleX = self.view.bounds.width / self.imageView.frame.width * 2 // Увеличиваем на 1.5 раза
                let scaleY = self.view.bounds.height / self.imageView.frame.height * 2 // Увеличиваем на 1.5 раза
                let scale = max(scaleX, scaleY)  // Увеличиваем изображение на большее значение по оси X или Y

                // Применяем масштабирование
                self.imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
                
                self.imageView.center = self.view.center
                
                print("Не нормальное состояние")
            })
        }
        
        // Переключаем флаг
        isFullScreen.toggle()
    }
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
            // Перемещаем изображение только в том случае, если оно увеличено
            guard isFullScreen else { return }
            
            let translation = gesture.translation(in: view)
            
            // Изменяем позицию изображения в зависимости от движения пальца
            if gesture.state == .changed {
                imageView.center = CGPoint(x: imageView.center.x + translation.x, y: imageView.center.y + translation.y)
                
                gesture.setTranslation(.zero, in: view)
            }
        }
    
    func updateFrame(_ frame: CGRect) {
//        UIView.animate(withDuration: 0.3) {
//            self.imageView.frame = frame
//        }
    }
    
    func updateNavigationBar() {
        let stackView = createNavigationTitleStack(name: item.name, creationDate: item.created)
        navigationItem.titleView = stackView
    }
    
    func displayImage(image: UIImage?) {
        imageView.image = image ?? UIImage(systemName: "photo")
    }
    
    @objc private func shareFoto() {
        guard let image = imageView.image  else { return }
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityController, animated: true)
    }
    
    @objc private func deleteFile() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let titleAction = UIAlertAction(title: "Current image will be deleted", style: .default, handler: nil)
        titleAction.setValue(UIColor.lightGray, forKey: "titleTextColor")
        let deleteAction = UIAlertAction(title: "Delete image", style: .destructive) { _ in
            self.deleteImage()
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
    
    private func deleteImage() {
        print("Изображение удалено")
    }
}



