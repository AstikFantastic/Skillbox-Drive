import UIKit

class LastFilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, LastFilesView {
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var presenter: LastLoadedFilesPresenter!
    private var router: Router!
    var files: [PublishedFile] = []
    var foldersData: [File] = []
    let tableView = UITableView()
    
    let pullToRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        let apiService = APIService()
        let navigationController = self.navigationController
        if let oAuthToken = UserDefaults.standard.string(forKey: "userToken") {
            router = Router(navigationController: navigationController!)
            presenter = LastLoadedFilesPresenter(view: self, oAuthToken: oAuthToken, apiService: apiService)
            presenter.fetchLastLoadedFiles()
        }
        tableView.dataSource = self
        tableView.delegate = self
        
        pullToRefreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        tableView.refreshControl = pullToRefreshControl
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleFileDeleted), name: NSNotification.Name("FileDeleted"), object: nil)
    }
    
    @objc private func handleFileDeleted() {
        // Например, можно перезагрузить данные
        presenter.fetchLastLoadedFiles()
        // Или просто обновить tableView, если данные уже обновлены
        tableView.reloadData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        title = "Last loaded"
        let backButton = UIBarButtonItem()
        backButton.title = ""
        navigationItem.backBarButtonItem = backButton

        setupActivityIndicator()
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        tableView.register(PublishedFilesCell.self, forCellReuseIdentifier: PublishedFilesCell.identifier)
    }
    
    func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .gray
        view.addSubview(activityIndicator)
        view.bringSubviewToFront(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    
    func showLoading() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
        }
    }
    
    func hideLoading() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }
    
    func showAllFiles(_ files: [PublishedFile]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.files = files
            self.foldersData.removeAll()
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }

    
    func showFolderData(_ folders: [File]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.foldersData = folders
            self.files.removeAll()
            self.tableView.reloadData()
            self.tableView.refreshControl = nil
        }
    }
    
    func showError(_ error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc private func didPullToRefresh(_ sender: UIRefreshControl) {
        presenter.fetchLastLoadedFiles()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PublishedFilesCell.identifier, for: indexPath) as? PublishedFilesCell else {
            return UITableViewCell()
        }
        
        let item = files[indexPath.row]
        let fileName = item.name
        let fileSize = presenter.formattedFileSize(from: item.size)
        let creationDate = DateFormatter.formattedString(from: item.created)
        cell.configureUnpublishButton(shouldShow: false)
        cell.configureNameLenght(-25)
        cell.setupCell(fileName: fileName, fileSize: fileSize, creationDate: creationDate)
        cell.setImage(item: item)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = files[indexPath.row]
        print("Выбран файл: \(file.name)")
        if let mediaType = file.mediaType {
            switch mediaType {
            case "document":
                if file.name.lowercased().hasSuffix(".pdf") {
                    router.navigateToPDFDetail(with: file)
                } else {
                    router.navigateToWebPage(with: file)
                }
            case "image":
                router.navigateToFileDetail(with: file)
            default:
                print("%)")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
}
