import UIKit

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
    
    func setImage(for item: Items) {
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
                        self?.previewImage.image = UIImage(named: "defaultImage")
                    }
                    self?.activityIndicator.stopAnimating()
                }
            }
        } else {
            previewImage.image = getFileTypeImage(for: item.mimeType)
            activityIndicator.stopAnimating()
        }
    }
    
    private func getFileTypeImage(for mimeType: String) -> UIImage? {
        switch mimeType {
        case "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
            return UIImage(named: "excel")
        case "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
            return UIImage(named: "word")
        case "application/vnd.openxmlformats-officedocument.presentationml.presentation":
            return UIImage(named: "powerpoint")
        case "application/pdf":
            return UIImage(named: "pdf")
        case "video/avi", "video/mp4", "video/m4v", "video/mov", "video/mpg", "video/mpeg", "video/wmv":
            return UIImage(named: "video")
        case "application/x-rar":
            return UIImage(named: "rar")
        case "audio/mpeg":
            return UIImage(named: "music")
        default:
            return UIImage(named: "camera.metering.unknown")
        }
    }
}

