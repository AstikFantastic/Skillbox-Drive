import UIKit

class LastFilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, LastFilesView {
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var presenter: LastLoadedFilesPresenter!
    private var router: Router!
    var files: [Items] = []
    let tableView = UITableView()
    
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
    }
    
    private func setupUI() {
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
    
    func showAllFiles(_ files: [Items]) {
        DispatchQueue.main.async { [weak self] in
            if files.isEmpty {
                print("No files found.")
            } else {
                self?.files = files
                self?.tableView.reloadData()
            }
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
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AllFilesCell.identifier, for: indexPath) as? AllFilesCell else {
            return UITableViewCell()
        }
        
        let item = files[indexPath.row]
        let fileName = item.name
        let fileSize = presenter.formattedFileSize(from: item.size)
        let creationDate = DateFormatter.formattedString(from: item.created)
        var fileImage: UIImage?
        
        cell.setupCell(fileName: fileName, fileSize: fileSize, creationDate: creationDate)
        
        if item.mediaType == "image" {
            if let previewURL = item.file {
                print("Attempting to load preview from URL: \(previewURL)")
                presenter.fetchImage(for: previewURL) { image in
                    if image != nil {
                        print("Successfully loaded image from \(previewURL)")
                    } else {
                        print("Failed to load image from \(previewURL)")
                    }
                    cell.setImage(image)
                }
            } else {
                print("Preview URL is missing for item: \(item)")
                cell.setImage(nil)
            }
        }
        
        switch item.mimeType {
        case "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
            fileImage = UIImage(named: "excel")  // Замените на имя изображения для Excel
        case "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
            fileImage = UIImage(named: "word")  // Замените на имя изображения для Word
        case "application/vnd.openxmlformats-officedocument.presentationml.presentation":
            fileImage = UIImage(named: "powerpoint")  // Замените на имя изображения для PowerPoint
        case "application/pdf":
            fileImage = UIImage(named: "pdf")
        case "video/avi", "video/mp4", "video/m4v","video/mov", "video/mpg", "video/mpeg", "video/wmv":
            fileImage = UIImage(named: "video")
        case "application/x-rar":
            fileImage = UIImage(named: "rar")
        case "audio/mpeg":
            fileImage = UIImage(named: "music")
        default:
            fileImage = UIImage(named: "Folder")  // Стандартное изображение для других типов
        }
        cell.setImage(fileImage)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = files[indexPath.row]
        print("Выбран файл: \(file.name)")
        if file.mimeType == "application/pdf" {
            router.navigateToPDFDetail(with: file)
        } else if file.mimeType == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" || file.mimeType == "application/vnd.openxmlformats-officedocument.wordprocessingml.document" || file.mimeType == "application/vnd.openxmlformats-officedocument.presentationml.presentation" {
            router.navigateToWebPage(with: file)
        } else {
            router.navigateToFileDetail(with: file)
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
}
