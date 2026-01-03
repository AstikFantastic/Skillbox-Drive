import PDFKit
import UIKit

class FileDetailPresenter {
    
    private weak var view: FileDetailViewProtocol?
    
    private let apiService: APIService
    private let oAuthToken: String
    private let publishedFile: PublishedFile
    
    /// Храним локальный URL, куда скачан файл (чтобы "Share" потом)
    private var localFileURL: URL?
    
    init(view: FileDetailViewProtocol,
         apiService: APIService,
         oAuthToken: String,
         file: PublishedFile)
    {
        self.view = view
        self.apiService = apiService
        self.oAuthToken = oAuthToken
        self.publishedFile = file
    }
    
    /// Запускаем общий флоу: запросить ссылку, скачать файл, показать
    func startDownloadFlow() {
        guard let path = publishedFile.path else {
            view?.showError("No path in publishedFile")
            return
        }
        
        view?.showLoading()
        
        // 1. Запрашиваем download link
        apiService.fetchDownloadLink(oAuthToken: oAuthToken, path: path) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let href):
                // 2. Скачиваем файл
                self.apiService.downloadFile(oAuthToken: self.oAuthToken, from: href) { downloadResult in
                    DispatchQueue.main.async {
                        self.view?.hideLoading()
                    }
                    switch downloadResult {
                    case .success(let fileData):
                        self.handleDownloadedData(fileData)
                        
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.view?.showError("Download error: \(error.localizedDescription)")
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.view?.hideLoading()
                    self.view?.showError("Cannot fetch download link: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Обработка загруженного Data
    private func handleDownloadedData(_ fileData: Data) {
        // Сохраняем во временное место
        let fileExtension = (publishedFile.name as NSString?)?.pathExtension.lowercased() ?? "tmp"
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
        
        do {
            try fileData.write(to: tempURL)
            self.localFileURL = tempURL
            
            // Определяем тип
            let ext = fileExtension.lowercased()
            
            DispatchQueue.main.async {
                // Говорим View включить кнопку Share
                self.view?.enableShare(with: tempURL)
                
                switch ext {
                case "jpg", "jpeg", "png", "gif":
                    if let image = UIImage(data: fileData) {
                        self.view?.showImage(image)
                    } else {
                        self.view?.showError("Cannot decode image")
                    }
                case "pdf":
                    if let doc = PDFDocument(url: tempURL) {
                        self.view?.showPDF(doc)
                    } else {
                        self.view?.showError("Cannot open PDF")
                    }
                case "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt":
                    self.view?.showDocumentWeb(tempURL)
                default:
                    // Пробуем WebView
                    self.view?.showDocumentWeb(tempURL)
                }
            }
            
        } catch {
            DispatchQueue.main.async {
                self.view?.showError("Failed to save file: \(error.localizedDescription)")
            }
        }
    }
    
    /// Функция share
    /// View вызывает её при нажатии на "Share", Presenter возвращает локальный URL
    func getLocalFileURLForSharing() -> URL? {
        return localFileURL
    }
}

extension FileDetailPresenter {
    func setView(_ view: FileDetailViewProtocol) {
        self.view = view
    }
}
