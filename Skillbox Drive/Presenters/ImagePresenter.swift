import UIKit

protocol FileDetailView: AnyObject {
    func displayImage(image: UIImage?)
    func updateNavigationBar()
}

protocol ImagePresenterProtocol: AnyObject {
    func onImagetapped()
}

class ImagePresenter {
    
    private var item: PublishedFile
    weak var view: FileDetailView?
    private let apiService: APIService
    private let oAuthToken: String
    private var model: ImageModel
    
    init(item: PublishedFile, oAuthToken: String, apiService: APIService) {
        self.item = item
        self.apiService = apiService
        self.oAuthToken = oAuthToken
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
    
    func deleteFile(permanently: String = "true", path: String) {
        apiService.deleteResource(oAuthToken: oAuthToken, baseURL: APIEndpoint.resources.url, permanently: permanently, path: path) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("File deleted")
                    if let vc = self.view as? UIViewController {
                        vc.navigationController?.popViewController(animated: true)
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("FileDeleted"), object: nil)
                    
                case .failure(let error):
                    print("Deletion error: \(error.localizedDescription)")
                    if let vc = self.view as? UIViewController {
                        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        vc.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func publishResource(completion: @escaping (Result<Void, Error>) -> Void) {
        let resourcePath = item.path ?? ""
        let availableUntil = Int(Date().addingTimeInterval(3600).timeIntervalSince1970) // 1 час
        let settings: [String: Any] = [
            "available_until": availableUntil,
            "accesses": [
                [
                    "type": "macro",
                    "macros": ["all"],
                    "rights": ["read"]
                ]
            ]
        ]
        
        apiService.publishResource(oAuthToken: oAuthToken, baseURL: APIEndpoint.publish.url, path: resourcePath, allowAddressAccess: true, publicSettings: settings) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Публикация успешна")
                    completion(.success(()))
                case .failure(let error):
                    print("Ошибка публикации: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    func fetchPublicURL(completion: @escaping (Result<String, Error>) -> Void) {
        let resourcePath = item.path ?? ""
        apiService.fetchResourceDetails(oAuthToken: oAuthToken, path: resourcePath) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let publicLink):
                    print("Получен public_url: \(publicLink)")
                    completion(.success(publicLink))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func renameFile(newName: String) {
         guard let oldPath = item.path else { return }
         let directory = (oldPath as NSString).deletingLastPathComponent
         let newPath = directory + "/" + newName
         
         apiService.moveResource(oAuthToken: oAuthToken, baseURL: APIEndpoint.rename.url, from: oldPath, to: newPath, overwrite: false, fields: "name,size,created,path,media_type,public_url") { [weak self] result in
             DispatchQueue.main.async {
                 switch result {
                 case .success(let publishedFile):
                     self?.apiService.fetchResourceDetailsNameAndCreated(oAuthToken: self!.oAuthToken, path: newPath) { result in
                         DispatchQueue.main.async {
                             switch result {
                             case .success(let json):
                                 if let updatedName = json["name"] as? String {
                                     self?.item = publishedFile.withNewNameAndDate(updatedName)
                                     if let vc = self?.view as? ImageViewController {
                                         vc.item = self!.item
                                         vc.navigationItem.title = updatedName
                                         vc.updateNavigationBar()
                                     }
                                 } else {
                                     self?.item = publishedFile
                                     if let vc = self?.view as? ImageViewController {
                                         vc.item = self!.item
                                         vc.navigationItem.title = publishedFile.name
                                         vc.updateNavigationBar()
                                     }
                                 }
                             case .failure(let error):
                                 print("Ошибка запроса обновлённой метаинформации: \(error)")
                                 self?.item = publishedFile
                                 if let vc = self?.view as? ImageViewController {
                                     vc.item = self!.item
                                     vc.navigationItem.title = publishedFile.name
                                     vc.updateNavigationBar()
                                 }
                             }
                         }
                     }
                 case .failure(let error):
                     print("Ошибка при переименовании: \(error)")
                     if let vc = self?.view as? UIViewController {
                         let alert = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
                         alert.addAction(UIAlertAction(title: "OK", style: .default))
                         vc.present(alert, animated: true, completion: nil)
                     }
                 }
             }
         }
     }

    func updateNavigationBar() {
        view?.updateNavigationBar()
    }
    
}

