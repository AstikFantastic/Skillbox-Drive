import UIKit

class PublishedFilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PublishedFilesView {
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var presenter: PublishedFilesPresenter!
    private var router: Router!
    private var reloadPublishedFiles = UIButton()
    private var imageView = UIImageView()
    private var descriptionLabel = UILabel()
    let tableView = UITableView()
    
    let pullToRefreshControl = UIRefreshControl()
    
    var files: [PublishedFile] = []
    var foldersData: [File] = []
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
            presenter.fetchLastLoadedFiles()
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        pullToRefreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        tableView.refreshControl = pullToRefreshControl
        
        reloadPublishedFiles.isHidden = true
        imageView.isHidden = true
        descriptionLabel.isHidden = true

    }
    
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "Published Files"
        let backButton = UIBarButtonItem()
        backButton.title = ""
        navigationItem.backBarButtonItem = backButton
        
        let backNavButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
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
    
    // MARK: - Loading / Error Handling
    
    private func updateRefreshControlState() {
        tableView.refreshControl = currentPathStack.isEmpty ? pullToRefreshControl : nil
    }
    
    private func updateEmptyState() {
        guard !activityIndicator.isAnimating else {
            reloadPublishedFiles.isHidden = true
            imageView.isHidden = true
            descriptionLabel.isHidden = true
            return
        }
        
        let isEmpty: Bool = currentPathStack.isEmpty ? files.isEmpty : foldersData.isEmpty
        reloadPublishedFiles.isHidden = !isEmpty
        imageView.isHidden = !isEmpty
        descriptionLabel.isHidden = !isEmpty
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
                self.updateEmptyState()
            }
    }
    
    func showAllFiles(_ files: [PublishedFile]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.files = files
            self.foldersData.removeAll()
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
            updateEmptyState()
        }
    }

    
    func showFolderData(_ folders: [File]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.foldersData = folders
            self.files.removeAll()
            self.tableView.reloadData()
            self.tableView.refreshControl = nil
            updateEmptyState()
        }
    }
    
    func showError(_ error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc private func refreshData() {
        presenter.fetchLastLoadedFiles()
    }
    
    @objc private func didPullToRefresh(_ sender: UIRefreshControl) {
        presenter.fetchLastLoadedFiles()
    }
    
    
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentPathStack.isEmpty ? files.count : foldersData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PublishedFilesCell.identifier, for: indexPath) as? PublishedFilesCell else {
            return UITableViewCell()
        }
        cell.delegate = self
        
        if currentPathStack.isEmpty {
            let item = files[indexPath.row]
            cell.configureUnpublishButton(shouldShow: true)
            cell.setupCell(fileName: item.name, fileSize: presenter.formattedFileSize(from: item.size), creationDate: DateFormatter.formattedString(from: item.created))
            cell.setImage(item: item)
            cell.filePath = item.path
        } else {
            cell.configureUnpublishButton(shouldShow: false)
            let item = foldersData[indexPath.row]
            let name = item.name
            cell.setupCell(fileName: name, fileSize: presenter.formattedFileSize(from: item.size ?? 0), creationDate: DateFormatter.formattedString(from: item.created))
            cell.setIconForFilesInFolders(item: item)
            cell.filePath = item.path
        }
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAt called, currentPathStack: \(currentPathStack)")
        
        if currentPathStack.isEmpty {
            let selectedItem = files[indexPath.row]
            print("Выбранный элемент из корня: \(selectedItem)")
            guard let type = selectedItem.type?.lowercased() else {
                print("Поле type отсутствует у выбранного элемента.")
                return
            }
            if type == "dir" {
                print("Переход в папку: \(selectedItem.path)")
                currentPathStack.append(selectedItem.path)
                presenter.fetchFolderContents(path: selectedItem.path)
            } else if type == "file" {
                if let mediaType = selectedItem.mediaType {
                    switch mediaType {
                    case "document":
                        router.navigateToWebPage(with: selectedItem)
                    case "image":
                        router.navigateToFileDetail(with: selectedItem)
                    default:
                        print("asdasd")
                    }
                    
                }
            }
        } else {
            let selectedItem = foldersData[indexPath.row]
            print("Выбранный элемент из папки: \(selectedItem)")
            guard let type = selectedItem.type else {
                print("Поле type отсутствует у выбранного элемента (в папке).")
                return
            }
            if type == "dir" {
                print("Переход в вложенную папку: \(selectedItem.path)")
                currentPathStack.append(selectedItem.path)
                presenter.fetchFolderContents(path: selectedItem.path)
            } else if type == "file" {
                if let mediaType = selectedItem.mediaType {
                    if mediaType == "document" || mediaType == "spreadsheet" {
                        print("Открытие файла внутри папки: \(selectedItem.name)")
                        
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    
    // MARK: - Actions
    
    @objc func backButtonTapped() {
        if !currentPathStack.isEmpty {
            currentPathStack.removeLast()
            if let lastPath = currentPathStack.last {
                print("Возврат к папке: \(lastPath)")
                presenter.fetchFolderContents(path: lastPath)
            } else {
                print("Возврат в корневую директорию")
                presenter.fetchLastLoadedFiles()
            }
        } else {
            router.returnToProfileVC()
        }
    }
    
    func showAlert(message: String, completion: @escaping () -> Void) {
        let aletr = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        aletr.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            completion()
        }))
        present(aletr, animated: true)
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
}

extension PublishedFilesViewController: PublishedFilesCellDelegate {
    func publishedFilesCell(_ cell: PublishedFilesCell, didTapUnpublishedButton button: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let titleAction = UIAlertAction(title: cell.displayedFileName, style: .default, handler: nil)
        titleAction.setValue(UIColor.lightGray, forKey: "titleTextColor")
        
        let deleteAction = UIAlertAction(title: "Unpublish file", style: .destructive) { _ in
            let resourcePath = cell.filePath ?? "Путь не найден"
            self.presenter.unpublishRespopnse(path: resourcePath)
            print("File unpublished")
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


