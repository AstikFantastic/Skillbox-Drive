import UIKit

class AllFilesCell: UITableViewCell {
    
    static let identifier = "AllFilesCell"
    
    private var fileName = UILabel()
    private var fileSize = UILabel()
    private var createdDate = UILabel()
    private var previewImage = UIImageView()

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
        NSLayoutConstraint.activate([
            previewImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            previewImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            previewImage.heightAnchor.constraint(equalToConstant: 22),
            previewImage.widthAnchor.constraint(equalToConstant: 25)
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
            fileSize.leadingAnchor.constraint(equalTo: previewImage.trailingAnchor, constant: 20),
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
    
    func setImage(_ image: UIImage?) {
        previewImage.image = image ?? UIImage(named: "Folder")
        }
}
