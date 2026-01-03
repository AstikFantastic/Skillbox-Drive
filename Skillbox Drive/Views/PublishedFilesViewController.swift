import UIKit

class PublishedFilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PublishedFilesView {

    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let tableView = UITableView()
    private let pullToRefreshControl = UIRefreshControl()
    
    private var reloadPublishedFiles = UIButton()
    private var imageView = UIImageView()
    private var descriptionLabel = UILabel()
    
    private var presenter: PublishedFilesPresenter!
    private var router: Router!
    
    private var isLoading = false
    
    var files: [PublishedFile] = []
    var foldersData: [PublishedFile] = []

    var currentPathStack: [String] = [] {
        didSet {
            updateRefreshControlState()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        guard let navigationController = self.navigationController else { return }
        let apiService = APIService()
        
        if let oAuthToken = UserDefaults.standard.string(forKey: "userToken") {
            router = Router(navigationController: navigationController)
            
            presenter = PublishedFilesPresenter(view: self, oAuthToken: oAuthToken, apiService: apiService)
            
            presenter.fetchPublishedFiles()
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        pullToRefreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        tableView.refreshControl = pullToRefreshControl
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleFileDeleted), name: NSNotification.Name("FileDeleted"), object: nil)
        
        reloadPublishedFiles.isHidden = true
        imageView.isHidden = true
        descriptionLabel.isHidden = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        presenter.fetchPublishedFiles()
    }
    
    @objc private func handleFileDeleted() {
        if currentPathStack.isEmpty {
            presenter.fetchPublishedFiles()
        } else {
            if let lastPath = currentPathStack.last {
                presenter.fetchFolderContents(path: lastPath)
            }
        }
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private func setupUI() {
        title = "Published Files"
        
        let backButton = UIBarButtonItem()
        backButton.title = ""
        navigationItem.backBarButtonItem = backButton
        
        let backNavButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backNavButton
        
        setupActivityIndicator()
        
        tableView.register(PublishedFilesCell.self, forCellReuseIdentifier: PublishedFilesCell.identifier)
        tableView.backgroundColor = .clear
        
        view.addSubview(tableView)
        view.addSubview(reloadPublishedFiles)
        view.addSubview(imageView)
        view.addSubview(descriptionLabel)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        reloadPublishedFiles.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        reloadPublishedFiles.setTitle("Refresh", for: .normal)
        reloadPublishedFiles.setTitleColor(.black, for: .normal)
        reloadPublishedFiles.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        reloadPublishedFiles.contentHorizontalAlignment = .center
        reloadPublishedFiles.layer.borderWidth = 0.33
        reloadPublishedFiles.layer.borderColor = CGColor(red: 241/255, green: 175/255, blue: 171/255, alpha: 1)
        reloadPublishedFiles.layer.cornerRadius = 10
        reloadPublishedFiles.backgroundColor = UIColor(red: 241/255, green: 175/255, blue: 171/255, alpha: 1)
        
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 17.5, bottom: 0, trailing: 0)
        reloadPublishedFiles.configuration = config
        reloadPublishedFiles.addTarget(self, action: #selector(refreshData), for: .touchUpInside)
        
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "empty published files")
        
        descriptionLabel.font = UIFont(name: "Graphik", size: 17)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.text = "You do not have any published files yet"

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            reloadPublishedFiles.heightAnchor.constraint(equalToConstant: 45),
            reloadPublishedFiles.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            reloadPublishedFiles.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 17.5),
            reloadPublishedFiles.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -17.5),
            
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 300),
            imageView.heightAnchor.constraint(equalToConstant: 147),
            imageView.widthAnchor.constraint(equalToConstant: 149),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 460),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 68),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -68)
        ])
    }
    
    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .gray
        activityIndicator.layer.zPosition = 1
        view.addSubview(activityIndicator)
        view.bringSubviewToFront(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func updateRefreshControlState() {
       tableView.refreshControl = currentPathStack.isEmpty ? pullToRefreshControl : nil
    }
    
    private func updateEmptyState() {
        guard !isLoading else { return }
        
        let isEmpty = currentPathStack.isEmpty ? files.isEmpty : foldersData.isEmpty
        
        if isEmpty {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let stillEmpty = self.currentPathStack.isEmpty ? self.files.isEmpty : self.foldersData.isEmpty
                if stillEmpty {
                    self.reloadPublishedFiles.isHidden = false
                    self.imageView.isHidden = false
                    self.descriptionLabel.isHidden = false
                }
            }
        } else {
            self.reloadPublishedFiles.isHidden = true
            self.imageView.isHidden = true
            self.descriptionLabel.isHidden = true
        }
    }
      
    func showLoading() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.activityIndicator.startAnimating()
            self.reloadPublishedFiles.isHidden = true
            self.imageView.isHidden = true
            self.descriptionLabel.isHidden = true
        }
    }

    func hideLoading() {
        DispatchQueue.main.async {
            self.isLoading = false
            self.activityIndicator.stopAnimating()
            self.updateEmptyState()
        }
    }

    
    func showAllFiles(_ files: [PublishedFile]) {
        DispatchQueue.main.async {
           
            self.files = files
            self.foldersData.removeAll()
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
            self.updateEmptyState()
        }
    }
    
    func showFolderData(_ folders: [PublishedFile]) {
        DispatchQueue.main.async {
            self.foldersData = folders
            self.files.removeAll()
            self.tableView.reloadData()
            self.tableView.refreshControl = nil
            self.updateEmptyState()
        }
    }
    
    func showError(_ error: Error) {
        DispatchQueue.main.async {
            let nsError = error as NSError
            if nsError.code == NSURLErrorNotConnectedToInternet ||
                nsError.code == NSURLErrorCannotFindHost {
                self.showNoInternetBanner(message: "No internet connection. Loading cache files")
                let cachedFiles = CoreDataManager.shared.fetchPublishedFiles(for: "PublishedFilesViewController")
                self.showAllFiles(cachedFiles)
            } else {
                let alert = UIAlertController(
                    title: "Error",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
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
    
    @objc private func refreshData() {
        if currentPathStack.isEmpty {
            presenter.fetchPublishedFiles()
        } else {
            if let lastPath = currentPathStack.last {
                presenter.fetchFolderContents(path: lastPath)
            }
        }
    }
    
    @objc private func didPullToRefresh(_ sender: UIRefreshControl) {
        refreshData()
    }
    
    @objc func backButtonTapped() {
        if !currentPathStack.isEmpty {
            currentPathStack.removeLast()
            if let lastPath = currentPathStack.last {
                presenter.fetchFolderContents(path: lastPath)
            } else {
                presenter.fetchPublishedFiles()
            }
        } else {
            router.returnToProfileVC()
        }
    }
    
    private func showAlertFormatNotSupported() {
        let alert = UIAlertController(title: "Not supported format", message: "It will work later", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
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
        cell.delegate = self
        
        if currentPathStack.isEmpty {
            let item = files[indexPath.row]
            cell.configureUnpublishButton(shouldShow: true)
            cell.setRightIndicatorTrailingConstant(-50)
            cell.setupCell(fileName: item.name ?? "", fileSize: presenter.formattedFileSize(from: item.size), creationDate: DateFormatter.formattedString(from: item.created)
            )
            cell.setImage(item: item)
            cell.filePath = item.path
        } else {
            let item = foldersData[indexPath.row]
            cell.configureUnpublishButton(shouldShow: false)
            cell.setRightIndicatorTrailingConstant(-50)
            cell.setupCell(fileName: item.name ?? "", fileSize: presenter.formattedFileSize(from: item.size ?? 0), creationDate: DateFormatter.formattedString(from: item.created)
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
                guard let cell = tableView.cellForRow(at: indexPath) as? PublishedFilesCell else { return }
                cell.showRightLoadingIndicator()
                presenter.downloadFile(path: selectedItem.path ?? "") { [weak self, weak cell] result in
                    DispatchQueue.main.async {
                        cell?.hideRightLoadingIndicator()
                    }
                    switch result {
                    case .success(_):
                        let fileExtension: String
                        if let name = selectedItem.name, !name.isEmpty {
                            fileExtension = (name as NSString).pathExtension.lowercased()
                        } else if let file = selectedItem.file, !file.isEmpty {
                            fileExtension = (file as NSString).pathExtension.lowercased()
                        } else {
                            fileExtension = ""
                        }
                        
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
                guard let cell = tableView.cellForRow(at: indexPath) as? PublishedFilesCell else { return }
                cell.showRightLoadingIndicator()
                presenter.downloadFile(path: selectedItem.path ?? "") { [weak self, weak cell] result in
                    DispatchQueue.main.async {
                        cell?.hideRightLoadingIndicator()
                    }
                    switch result {
                    case .success(_):
                        let fileExtension: String
                        if let name = selectedItem.name, !name.isEmpty {
                            fileExtension = (name as NSString).pathExtension.lowercased()
                        } else if let file = selectedItem.file, !file.isEmpty {
                            fileExtension = (file as NSString).pathExtension.lowercased()
                        } else {
                            fileExtension = ""
                        }
                        
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


func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let offsetY = scrollView.contentOffset.y
    let contentHeight = scrollView.contentSize.height
    let frameHeight = scrollView.frame.size.height
    
    if offsetY > contentHeight - frameHeight - 200 {
        if currentPathStack.isEmpty {
            presenter.loadNextPagePublishedIfNeeded()
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

extension PublishedFilesViewController: PublishedFilesCellDelegate {
    func publishedFilesCell(_ cell: PublishedFilesCell,
                            didTapUnpublishedButton button: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let titleAction = UIAlertAction(title: cell.displayedFileName, style: .default, handler: nil)
        titleAction.setValue(UIColor.lightGray, forKey: "titleTextColor")
        
        let unpublishAction = UIAlertAction(title: "Unpublish file", style: .destructive) { _ in
            let resourcePath = cell.filePath ?? "Path not found"
            self.presenter.unpublishRespopnse(path: resourcePath)
            print("File unpublished")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(titleAction)
        alert.addAction(unpublishAction)
        alert.addAction(cancelAction)
        
        if let firstAction = alert.actions.first {
            firstAction.isEnabled = false
        }
        
        present(alert, animated: true)
    }
}
