import UIKit
import WebKit

class OfficeViewController: UIViewController, OfficeView {
    
    private let presenter: OfficePresenter
    private var webView: WKWebView!
    private let item: PublishedFile
    private let apiService: APIService
    
    private let linkButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    
    init(presenter: OfficePresenter, item: PublishedFile, apiService: APIService) {
        self.item = item
        self.presenter = presenter
        self.apiService = apiService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        presenter.attachView(self)
        presenter.loadPage()
        presenter.updateNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        tabBarController?.isTabBarHidden = false
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        let backNavButton = UIBarButtonItem(image: UIImage(systemName: "rectangle.and.pencil.and.ellipsis"), style: .plain, target: self, action: #selector(renameButtonTapped))
        navigationItem.rightBarButtonItem = backNavButton
        
        tabBarController?.isTabBarHidden = true
        
 
        
        let configuration = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        view.addSubview(webView)
        view.addSubview(linkButton)
        view.addSubview(deleteButton)

        webView.translatesAutoresizingMaskIntoConstraints = false
        linkButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        linkButton.setImage(UIImage(named: "link"), for: .normal)
        linkButton.tintColor = .blue
        linkButton.translatesAutoresizingMaskIntoConstraints = false
        linkButton.addTarget(self, action: #selector(sharePDF), for: .touchUpInside)
        
        deleteButton.setImage(UIImage(named: "trash"), for: .normal)
        deleteButton.tintColor = .red
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteFile), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            
            linkButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            linkButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 54),
            
            deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -54),

            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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
    
    @objc func sharePDF() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let shareFileAction = UIAlertAction(title: "Поделиться файлом", style: .default) { _ in
        
            let fileName = (self.item.path! as NSString).lastPathComponent
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent(fileName)
                
                guard FileManager.default.fileExists(atPath: documentsURL.path) else {
                    let errorAlert = UIAlertController(title: "Ошибка", message: "Файл не найден.", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                    return
                }
                
                let activityController = UIActivityViewController(activityItems: [documentsURL], applicationActivities: nil)

                self.present(activityController, animated: true)
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
    
    @objc func deleteFile() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let titleAction = UIAlertAction(title: "Current file will be deleted", style: .default, handler: nil)
        titleAction.setValue(UIColor.lightGray, forKey: "titleTextColor")
        let deleteAction = UIAlertAction(title: "Delete file", style: .destructive) { _ in
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
    
    func loadURL(_ url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func updateNavigationBar() {
        let stackView = createNavigationTitleStack(name: item.name, creationDate: item.created)
        navigationItem.titleView = stackView
    }
    
  
}
