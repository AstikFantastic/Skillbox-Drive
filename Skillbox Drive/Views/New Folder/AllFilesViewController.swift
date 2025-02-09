import UIKit

class AllFilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FilesView {
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var presenter: AllFilesPresenter!
    var files: [Item] = []
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        if let oAuthToken = UserDefaults.standard.string(forKey: "userToken") {
            let apiService = APIService()
            presenter = AllFilesPresenter(view: self, oAuthToken: oAuthToken, apiService: apiService)
            presenter.fetchAllFiles()
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
            print("Can see indicator")
        }
    }
    
    func hideLoading() {
      
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
         print("Hide indicator")
        }
    }
    
    func showAllFiles(_ files: [Item]) {
        DispatchQueue.main.async { [weak self] in
            self?.files = files
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
        cell.setupCell(fileName: fileName, fileSize: fileSize, creationDate: creationDate)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = files[indexPath.row]
        print("Выбран файл: \(selectedItem.name)")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    
    
}
