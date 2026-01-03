import UIKit

final class RenameViewController: UIViewController {
    
    var currentName: String = ""
    var onRename: ((String) -> Void)?
    
    private let textField = UITextField()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarController?.isTabBarHidden = true
        
        view.backgroundColor = .white
        title = "Rename"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem( title: "Готово", style: .done, target: self, action: #selector(doneTapped))
        textField.delegate = self
        setupTextField()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.isTabBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let text = textField.text,
              let dotRange = text.range(of: ".", options: .backwards) else {
            return
        }
        
        let offset = text.distance(from: text.startIndex, to: dotRange.lowerBound)
        
        if let position = textField.position(from: textField.beginningOfDocument, offset: offset) {
            textField.selectedTextRange = textField.textRange(from: position, to: position)
        }
    }
    
    
    private func setupTextField() {
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.text = currentName
        textField.clearButtonMode = .whileEditing
        
        view.addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textField.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        DispatchQueue.main.async {
            self.textField.becomeFirstResponder()
        }
    }
    
    @objc private func doneTapped() {
        let newName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !newName.isEmpty else { return }
        
        onRename?(newName)
        
        navigationController?.popViewController(animated: true)
    }
}

extension RenameViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        
        guard let dotRange = currentName.range(of: ".", options: .backwards) else {
            return true
        }
        let extString = String(currentName[dotRange.lowerBound...])
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        if newText == extString {
            return false
        }
        if !newText.hasSuffix(extString) {
            return false
        }
        let extensionStartIndex = currentName.distance(from: currentName.startIndex, to: dotRange.lowerBound)
        if range.location >= extensionStartIndex {
            return false
        }
        if range.location + range.length > extensionStartIndex {
            return false
        }
        
        return true
    }
}
