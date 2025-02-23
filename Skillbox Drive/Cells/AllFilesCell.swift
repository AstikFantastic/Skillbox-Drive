import UIKit

protocol ImageRepresentable {
    var file: String? { get }
    var mediaType: String? { get }
    var mimeType: String? { get }
    var type: String? { get }
}

class AllFilesCell: UITableViewCell {
    
    static let identifier = "AllFilesCell"
    
    private var fileName = UILabel()
    private var fileSize = UILabel()
    private var createdDate = UILabel()
    private var previewImage = UIImageView()
    private var activityIndicator = UIActivityIndicatorView(style: .medium)
    private var currentImageURL: String?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        previewImage.translatesAutoresizingMaskIntoConstraints = false
        previewImage.sizeThatFits(CGSize(width: 25, height: 22))
        previewImage.contentMode = .scaleAspectFit
        contentView.addSubview(previewImage)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        contentView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            previewImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            previewImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            previewImage.heightAnchor.constraint(equalToConstant: 22),
            previewImage.widthAnchor.constraint(equalToConstant: 25),
            
            activityIndicator.centerYAnchor.constraint(equalTo: previewImage.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: previewImage.centerXAnchor)
        ])
        
        fileName.font = .systemFont(ofSize: 15)
        fileName.numberOfLines = 1
        fileName.lineBreakMode = .byTruncatingMiddle
        contentView.addSubview(fileName)
        fileName.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fileName.leadingAnchor.constraint(equalTo: previewImage.trailingAnchor, constant: 10),
            fileName.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            fileName.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
        ])
        
        fileSize.font = .systemFont(ofSize: 13)
        fileSize.textColor = .lightGray
        contentView.addSubview(fileSize)
        fileSize.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fileSize.leadingAnchor.constraint(equalTo: previewImage.trailingAnchor, constant: 10),
            fileSize.topAnchor.constraint(equalTo: fileName.bottomAnchor, constant: 3)
        ])
        
        createdDate.font = .systemFont(ofSize: 13)
        createdDate.textColor = .lightGray
        contentView.addSubview(createdDate)
        createdDate.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            createdDate.leadingAnchor.constraint(equalTo: fileSize.trailingAnchor, constant: 5),
            createdDate.centerYAnchor.constraint(equalTo: fileSize.centerYAnchor)
        ])
    }
    
    func setupCell(fileName: String, fileSize: String, creationDate: String) {
        
        self.fileName.text = fileName
        self.fileSize.text = fileSize
        self.createdDate.text = creationDate
    }
    
    func setImage(item: PublishedFile) {
        activityIndicator.startAnimating()
        previewImage.image = nil
        
        if currentImageURL == item.file {
            activityIndicator.stopAnimating()
            return
        }
        
        currentImageURL = item.file
        
        if item.mediaType == "image", let previewURL = item.file {
            APIService.shared.fetchImage(from: previewURL) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let image):
                        self?.previewImage.image = image
                    case .failure:
                        self?.previewImage.image = UIImage(named: "questionmark")
                    }
                    self?.activityIndicator.stopAnimating()
                }
            }
        }
        // Если это документ, проверяем расширение файла
        else if item.mediaType == "document" {
            let fileExtension: String
            if !item.name.isEmpty {
                fileExtension = (item.name as NSString).pathExtension.lowercased()
            } else if let file = item.file, !file.isEmpty {
                fileExtension = (file as NSString).pathExtension.lowercased()
            } else {
                fileExtension = ""
            }
            switch fileExtension {
            case "pdf":
                previewImage.image = UIImage(named: "pdf")
            case "doc", "docx", "txt":
                previewImage.image = UIImage(named: "word")
            case "xls", "xlsx":
                previewImage.image = UIImage(named: "excel")
            case "pptx", "ptx":
                previewImage.image = UIImage(named: "powerpoint")
            default:
                previewImage.image = UIImage(named: "document")
            }
            activityIndicator.stopAnimating()
        }
        else {
            previewImage.image = UIImage(named: "questionmark")
            activityIndicator.stopAnimating()
        }
    }
}
