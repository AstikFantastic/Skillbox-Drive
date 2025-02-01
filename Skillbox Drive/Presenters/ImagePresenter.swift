import UIKit

protocol FileDetailView: AnyObject {
    func displayImage(image: UIImage?)
}

protocol ImagePresenterProtocol: AnyObject {
    func onImagetapped()
}

class ImagePresenter {
    
    private let item: Items
    weak var view: FileDetailView?
    private let apiService: APIService
    private var model: ImageModel
    
    init(item: Items, apiService: APIService) {
        self.item = item
        self.apiService = apiService
        self.model = ImageModel(name: "Name", image: UIImage(systemName: "photo")!, isFullScreen: false)
    }
    
    func attachView(_ view: FileDetailView) {
        self.view = view
    }
    
    func loadImage() {
        var previewImage: UIImage? = UIImage(named: "photo")
        
        if let previewURL = item.file {
            apiService.fetchImage(from: previewURL) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let image):
                        previewImage = image
                        self?.view?.displayImage(image: previewImage)
                    case .failure(let error):
                        print("Ошибка загрузки изображения: \(error.localizedDescription)")
                        self?.view?.displayImage(image: previewImage)
                    }
                }
            }
        } else {
            view?.displayImage(image: previewImage)
        }
    }
    
    func updateNavigationBar() {
        if let viewController = view as? UIViewController {
            let stackView = viewController.createNavigationTitleStack(name: item.name, creationDate: item.created)
            viewController.navigationItem.titleView = stackView
        }
    }
    
    func onImagetapped() {
        model.isFullScreen.toggle()
        
        let newFrame: CGRect
        
        if model.isFullScreen {
            newFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        } else {
            newFrame = CGRect(x: 50, y: 100, width: 300, height: 300)
        }
        if let view = view as? ImageViewProtocol {
            view.updateFrame(newFrame)
        }
    }
}

