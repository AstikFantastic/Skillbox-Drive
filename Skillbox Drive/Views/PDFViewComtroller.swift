import UIKit
import PDFKit

class PDFViewController: UIViewController {
    private let presenter: PDFPresenter

    init(presenter: PDFPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        let pdfView = PDFView(frame: view.bounds)
        view.addSubview(pdfView)

        let item = presenter.getPDFItem()
        title = item.name
        pdfView.autoScales = true

        if let document = PDFDocument(url: item.fileURL) {
            pdfView.document = document
        } else {
            print("Failed to load PDF.")
        }
    }
}
