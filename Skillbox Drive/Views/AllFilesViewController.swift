import UIKit

class AllFilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FilesView {
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let tableView = UITableView()
    private let pullToRefreshControl = UIRefreshControl()
    
    private var presenter: AllFilesPresenter!
    var router: Router!
    
    var files: [PublishedFile] = []
    var foldersData: [PublishedFile] = []
    
    var currentPathStack: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        guard let navigationController = self.navigationController else { return }
        
        let apiService = APIService()
        if let oAuthToken = UserDefaults.standard.string(forKey: "userToken") {
            router = Router(navigationController: navigationController)
            
            
            presenter = AllFilesPresenter(view: self, oAuthToken: oAuthToken, apiService: apiService)
            
            presenter.fetchAllFiles()
        }
    
        tableView.dataSource = self
        tableView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleFileDeleted), name: NSNotification.Name("FileDeleted"), object: nil)
        
        pullToRefreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        tableView.refreshControl = pullToRefreshControl
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleFileDeleted() {
        if currentPathStack.isEmpty {
            presenter.fetchAllFiles()
        } else {
            if let lastPath = currentPathStack.last {
                presenter.fetchFolderContents(path: lastPath)
            }
        }
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func setupUI() {
        title = "All files"
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .gray
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        tableView.register(PublishedFilesCell.self,
                           forCellReuseIdentifier: PublishedFilesCell.identifier)
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        updateLeftBarButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        presenter.fetchAllFiles()
    }
    
    private func updateLeftBarButton() {
        if currentPathStack.isEmpty {
            navigationItem.leftBarButtonItem = nil
        } else {
            let backNavButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped)
            )
            navigationItem.leftBarButtonItem = backNavButton
        }
    }
    
    @objc private func didPullToRefresh(_ sender: UIRefreshControl) {
        if currentPathStack.isEmpty {
            presenter.fetchAllFiles()
        } else {
            if let lastPath = currentPathStack.last {
                presenter.fetchFolderContents(path: lastPath)
            }
        }
    }
    
    @objc func backButtonTapped() {
        if !currentPathStack.isEmpty {
            currentPathStack.removeLast()
            if let lastPath = currentPathStack.last {
                presenter.fetchFolderContents(path: lastPath)
            } else {
                presenter.fetchAllFiles()
            }
        } else {
            router.returnToProfileVC()
        }
        updateLeftBarButton()
    }
    
    private func showAlertFormatNotSupported() {
        let alert = UIAlertController(title: "Not supported format",  message: "It will work later", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    func showLoading() {
        DispatchQueue.main.async {
            if self.tableView.refreshControl?.isRefreshing == false {
                self.activityIndicator.startAnimating()
            }
        }
    }
    
    func hideLoading() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    func showAllFiles(_ files: [PublishedFile]) {
        DispatchQueue.main.async {
            self.files = files
            self.foldersData.removeAll()
            self.tableView.reloadData()
            self.updateLeftBarButton()
        }
    }
    
    func showFolderData(_ files: [PublishedFile]) {
        DispatchQueue.main.async {
            self.foldersData = files
            self.files.removeAll()
            self.tableView.reloadData()
            self.updateLeftBarButton()
        }
    }
    
    func showError(_ error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func showNoInternetBanner(message: String) {
        let banner = UILabel()
        banner.backgroundColor = UIColor.red.withAlphaComponent(0.8)
        banner.textColor = .white
        banner.textAlignment = .center
        banner.numberOfLines = 0
        banner.text = message
        banner.alpha = 0
        
        view.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            banner.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.3) {
            banner.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 0.3, animations: {
                banner.alpha = 0
            }, completion: { _ in
                banner.removeFromSuperview()
            })
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentPathStack.isEmpty ? files.count : foldersData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PublishedFilesCell.identifier,
            for: indexPath
        ) as? PublishedFilesCell else {
            return UITableViewCell()
        }
        
        if currentPathStack.isEmpty {
            let item = files[indexPath.row]
            cell.configureNameLenght(-100)
            cell.configureUnpublishButton(shouldShow: false)
            cell.setupCell(
                fileName: item.name ?? "",
                fileSize: presenter.formattedFileSize(from: item.size),
                creationDate: DateFormatter.formattedString(from: item.created)
            )
            cell.setImage(item: item)
            cell.filePath = item.path
            
        } else {
            let item = foldersData[indexPath.row]
            cell.configureNameLenght(-100)
            cell.configureUnpublishButton(shouldShow: false)
            cell.setupCell(
                fileName: item.name ?? "",
                fileSize: presenter.formattedFileSize(from: item.size),
                creationDate: DateFormatter.formattedString(from: item.created)
            )
            cell.setIconForFilesInFolders(item: item)
            cell.filePath = item.path
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if currentPathStack.isEmpty {
            let selectedItem = files[indexPath.row]
            if selectedItem.type == "dir" {
                currentPathStack.append(selectedItem.path ?? "")
                presenter.fetchFolderContents(path: selectedItem.path ?? "")
            } else if selectedItem.type == "file" {
                let fileExtension: String
                if let name = selectedItem.name, !name.isEmpty {
                    fileExtension = (name as NSString).pathExtension.lowercased()
                } else if let file = selectedItem.file, !file.isEmpty {
                    fileExtension = (file as NSString).pathExtension.lowercased()
                } else {
                    fileExtension = ""
                }
                
                guard isSupportedFormat(fileExtension) else {
                    showAlertFormatNotSupported()
                    return
                }
                
                guard let cell = tableView.cellForRow(at: indexPath) as? PublishedFilesCell else { return }
                cell.showRightLoadingIndicator()
                
                presenter.downloadFile(path: selectedItem.path ?? "") { [weak self, weak cell] result in
                    DispatchQueue.main.async {
                        cell?.hideRightLoadingIndicator()
                    }
                    switch result {
                    case .success(_):
                        DispatchQueue.main.async {
                            switch fileExtension {
                            case "pdf":
                                self?.router.navigateToPDFDetail(with: selectedItem)
                            case "doc", "docx", "txt", "xls", "xlsx", "pptx", "ptx":
                                self?.router.navigateToWebPage(with: selectedItem)
                            case "jpg", "jpeg", "png":
                                self?.router.navigateToFileDetail(with: selectedItem)
                            default:
                                self?.showAlertFormatNotSupported()
                            }
                        }
                    case .failure(_):
                        DispatchQueue.main.async {
                            print("")
                        }
                    }
                }
            }
        } else {
            let selectedItem = foldersData[indexPath.row]
            if selectedItem.type == "dir" {
                currentPathStack.append(selectedItem.path ?? "")
                presenter.fetchFolderContents(path: selectedItem.path ?? "")
            } else if selectedItem.type == "file" {
                let fileExtension: String
                if let name = selectedItem.name, !name.isEmpty {
                    fileExtension = (name as NSString).pathExtension.lowercased()
                } else if let file = selectedItem.file, !file.isEmpty {
                    fileExtension = (file as NSString).pathExtension.lowercased()
                } else {
                    fileExtension = ""
                }
                
                guard isSupportedFormat(fileExtension) else {
                    showAlertFormatNotSupported()
                    return
                }
                
                guard let cell = tableView.cellForRow(at: indexPath) as? PublishedFilesCell else { return }
                cell.showRightLoadingIndicator()
                presenter.downloadFile(path: selectedItem.path ?? "") { [weak self, weak cell] result in
                    DispatchQueue.main.async {
                        cell?.hideRightLoadingIndicator()
                    }
                    switch result {
                    case .success(_):
                        DispatchQueue.main.async {
                            switch fileExtension {
                            case "pdf":
                                self?.router.navigateToPDFDetail(with: selectedItem)
                            case "doc", "docx", "txt", "xls", "xlsx", "pptx", "ptx":
                                self?.router.navigateToWebPage(with: selectedItem)
                            case "jpg", "jpeg", "png":
                                self?.router.navigateToFileDetail(with: selectedItem)
                            default:
                                self?.showAlertFormatNotSupported()
                            }
                        }
                    case .failure(_):
                        DispatchQueue.main.async {
                            print("")
                        }
                    }
                }
            }
        }
    }

    private func isSupportedFormat(_ fileExtension: String) -> Bool {
        let supportedFormats: Set<String> = ["pdf", "doc", "docx", "txt", "xls", "xlsx", "pptx", "ptx", "jpg", "jpeg", "png"]
        return supportedFormats.contains(fileExtension)
    }

    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        
        if offsetY > contentHeight - frameHeight - 200 {
            if currentPathStack.isEmpty {
                presenter.loadNextPageAllFilesIfNeeded()
            } else {
                presenter.loadNextPageFolderIfNeeded()
            }
        }
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
}
