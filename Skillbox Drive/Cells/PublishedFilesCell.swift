import Foundation
import UIKit

protocol PublishedFilesCellDelegate: AnyObject {
    func publishedFilesCell(_ cell: PublishedFilesCell, didTapUnpublishedButton button: UIButton)
}

class PublishedFilesCell: UITableViewCell {
    
    static let identifier = "PublishedFilesCell"
    
    weak var delegate: PublishedFilesCellDelegate?
    
    public var fileName = UILabel()
    private var fileSize = UILabel()
    private var createdDate = UILabel()
    private var previewImage = UIImageView()
    private let unpublishedButton = UIButton(type: .custom)
    private var activityIndicator = UIActivityIndicatorView(style: .medium)
    private var currentImageURL: String?
    var displayedFileName: String? {
        return fileName.text
    }
    func configureUnpublishButton(shouldShow: Bool) {
            unpublishedButton.isHidden = !shouldShow
    }
    
    public var filePath: String?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        previewImage.image = nil
        currentImageURL = nil
        activityIndicator.stopAnimating()
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
            fileName.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -100),
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
        
        
        unpublishedButton.frame = CGRect(x: 50, y: 50, width: 50, height: 50)
        unpublishedButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        unpublishedButton.tintColor = .gray
        unpublishedButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        unpublishedButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(unpublishedButton)
        NSLayoutConstraint.activate([
            unpublishedButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            unpublishedButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
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

        if item.type == "dir" {
            previewImage.image = UIImage(named: "folder")
        }

        if currentImageURL == item.file {
            activityIndicator.stopAnimating()
            return
        }

        currentImageURL = item.file

        if item.mediaType == "image", let previewURL = currentImageURL {
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
            previewImage.image = UIImage(systemName: "questionmark")
            activityIndicator.stopAnimating()
        }
    }
    
    func setIconForFilesInFolders(item: File) {
        activityIndicator.startAnimating()
        previewImage.image = nil
        
        if item.type == "dir" {
            previewImage.image = UIImage(named: "folder")
        } else if item.type == "file" {
            let imageURLString = item.file
            if let mimeType = item.mimeType, let urlString = imageURLString {
                print("Setting icon for file in folder with mimeType: \(mimeType.lowercased())")
                switch mimeType.lowercased() {
                case "image/jpeg", "image/png":
                    APIService.shared.fetchImage(from: urlString) { [weak self] result in
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
                    return
                case "application/pdf":
                    previewImage.image = UIImage(named: "pdf")
                case "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
                    previewImage.image = UIImage(named: "excel")
                case "application/vnd.openxmlformats-officedocument.presentationml.presentation":
                    previewImage.image = UIImage(named: "powerpoint")
                case "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
                    previewImage.image = UIImage(named: "word")
                default:
                    previewImage.image = UIImage(systemName: "questionmark")
                }
            } else {
                print("Missing mimeType or URL for file inside folder")
                previewImage.image = UIImage(named: "questionmark")
            }
            activityIndicator.stopAnimating()
        }
        
        if currentImageURL == item.file {
            activityIndicator.stopAnimating()
            return
        }

    }
    
    @objc func buttonTapped() {
        print("Button")
        delegate?.publishedFilesCell(self, didTapUnpublishedButton: unpublishedButton)
    }
    
    
}
