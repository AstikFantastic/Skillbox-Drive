import UIKit

class PublishedFilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PublishedFilesView {

    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var presenter: PublishedFilesPresenter!
    private var router: Router!
    var files: [PublishedFile] = []
    var foldersData: [File] = []
    var currentPath: String?
    let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        let apiService = APIService()
        let navigationController = self.navigationController
        if let oAuthToken = UserDefaults.standard.string(forKey: "userToken") {
            router = Router(navigationController: navigationController!)
            presenter = PublishedFilesPresenter(view: self, oAuthToken: oAuthToken, apiService: apiService)
            presenter.fetchLastLoadedFiles()
        }
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func setupUI() {
        title = "Published Files"
        let backButton = UIBarButtonItem()
        backButton.title = ""
        navigationItem.backBarButtonItem = backButton

        let backNavButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backNavButton
        
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
        tableView.register(AllFilesCell.self, forCellReuseIdentifier: AllFilesCell.identifier)
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
            self?.files = files
            self?.foldersData.removeAll()
            self?.currentPath = nil
            self?.tableView.reloadData()
        }
    }

    func showFolderData(_ folders: [File]) {
        DispatchQueue.main.async { [weak self] in
            self?.foldersData = folders
            self?.files.removeAll()
            self?.tableView.reloadData()
        }
    }

    func showError(_ error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentPath != nil {
            return foldersData.count
        } else {
            return files.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AllFilesCell.identifier, for: indexPath) as? AllFilesCell else {
                return UITableViewCell()
            }

        if currentPath != nil {
            let item = foldersData[indexPath.row]
            let fileSize = presenter.formattedFileSize(from: item.size ?? 0)
            cell.setupCell(fileName: item.path, fileSize: fileSize, creationDate: item.created ?? "Lost creation data")
        } else {
            let item = files[indexPath.row]
            let fileName = item.name
            let fileSize = presenter.formattedFileSize(from: item.size)
            let creationDate = item.created
            cell.setupCell(fileName: fileName, fileSize: fileSize, creationDate: creationDate)
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if currentPath != nil {
            let selectedFolder = foldersData[indexPath.row]
            presenter.fetchFolderContents(path: selectedFolder.path)
            currentPath = selectedFolder.path
        } else {
            let selectedFile = files[indexPath.row]
            if selectedFile.type == "dir" {
                presenter.fetchFolderContents(path: selectedFile.path)
                currentPath = selectedFile.path
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }

    // MARK: - Actions

    @objc func backButtonTapped() {
        if let _ = currentPath {
            currentPath = nil
            presenter.fetchLastLoadedFiles()
        }
    }
}
