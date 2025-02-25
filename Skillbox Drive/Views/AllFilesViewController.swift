import UIKit


class AllFilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FilesView {
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var presenter: AllFilesPresenter!
    var router: Router!
    var files: [File] = []
    var foldersData: [File] = []
    
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        if let oAuthToken = UserDefaults.standard.string(forKey: "userToken") {
            let apiService = APIService.shared
            router = Router(navigationController: navigationController!)
            presenter = AllFilesPresenter(view: self, oAuthToken: oAuthToken, apiService: apiService)
            presenter.fetchAllFiles(path: "disk:/")
        }
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func setupUI() {
        title = "All files"
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
            print("Can see indicator")
        }
    }
    
    func hideLoading() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            print("Hide indicator")
        }
    }
    
    func showAllFiles(_ files: [File]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.files = files
            self.foldersData.removeAll()
            self.tableView.reloadData()
        }
    }
    
    func showFolderData(_ folders: [File]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.foldersData = folders
            self.files.removeAll()
            self.tableView.reloadData()
        }
    }
    
    func showError(_ error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
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
        let creationDate = DateFormatter.formattedString(from: item.created ?? "")
        cell.configureUnpublishButton(shouldShow: false)
        cell.configureNameLenght(-25)
        cell.setupCell(fileName: fileName, fileSize: fileSize, creationDate: creationDate)
//        cell.setImage(item: item)
        
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
//                    router.navigateToPDFDetail(with: file)
                } else {
//                    router.navigateToWebPage(with: file)
                }
            case "image":
                print()
//                router.navigateToFileDetail(with: file)
            default:
                print("Неизвестный тип файла")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
}
