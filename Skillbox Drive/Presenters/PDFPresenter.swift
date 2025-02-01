import UIKit
import PDFKit

class PDFPresenter {
    private let item: Items
    private let pdfFile: PDFModel
    weak var view: PDFViewProtocol?
    
    init(item: Items, pdfFile: PDFModel) {
        self.item = item
        self.pdfFile = pdfFile
    }
    
    func attachView(_ view: PDFViewProtocol) {
        self.view = view
    }
    
    func loadPDF() {
        guard let document = PDFDocument(url: pdfFile.fileURL) else {
            view?.showError(message: "Failed to load PDF.")
            return
        }
        view?.displayPDF(document: document)
    }
    
    func updateNavigationBar() {
        if let viewController = view as? UIViewController {
            let stackView = viewController.createNavigationTitleStack(name: item.name, creationDate: item.created)
            viewController.navigationItem.titleView = stackView
        }
    }
}
