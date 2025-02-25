import UIKit
import PDFKit

protocol PDFViewProtocol: AnyObject {
    func displayPDF(document: PDFDocument)
    func showError(message: String)
    func updateNavigationBar()
}

class PDFPresenter {
    private let item: PublishedFile
    private let pdfFile: PDFModel
    weak var view: PDFViewProtocol?
    
    init(item: PublishedFile, pdfFile: PDFModel) {
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
        view?.updateNavigationBar()
    }
}
