import UIKit
import PDFKit

class PDFViewController: UIViewController, PDFViewProtocol {
    
    private let item: PublishedFile
    private let presenter: PDFPresenter
    private var pdfView: PDFView!

    init(presenter: PDFPresenter, item: PublishedFile) {
        self.presenter = presenter
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        presenter.attachView(self)
        presenter.loadPDF()
        presenter.updateNavigationBar()
    }

    private func setupUI() {
        pdfView = PDFView(frame: view.bounds)
        pdfView.autoScales = true
        view.addSubview(pdfView)
    }

    func displayPDF(document: PDFDocument) {
        pdfView.document = document
    }
    
    func updateNavigationBar() {
        let stackView = createNavigationTitleStack(name: item.name, creationDate: item.created)
        navigationItem.titleView = stackView
    }

    func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
