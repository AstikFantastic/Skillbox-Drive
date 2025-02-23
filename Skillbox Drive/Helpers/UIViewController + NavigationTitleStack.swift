import UIKit

extension UIViewController {
    func createNavigationTitleStack(name: String?, creationDate: String?) -> UIStackView {
        let titleLabel = UILabel()

        titleLabel.text = name
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byTruncatingMiddle
        
        let dateLabel = UILabel()
        dateLabel.text = DateFormatter.formattedString(from: creationDate)
        dateLabel.font = UIFont.systemFont(ofSize: 10)
        dateLabel.textColor = .lightGray
        dateLabel.textAlignment = .center
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .center
        
        return stackView
    }
}
