import UIKit

class PDFPresenter {
    private let item: PDFModel

    init(item: PDFModel) {
        self.item = item
    }

    func getPDFItem() -> PDFModel {
        return item
    }
}
