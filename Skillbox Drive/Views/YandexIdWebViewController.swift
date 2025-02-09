import UIKit
import WebKit

class YandexIdWebViewController: UIViewController {
    
    var webView: WKWebView!
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView(frame: self.view.bounds)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
        
        if let authorizationURL = url {
            let request = URLRequest(url: authorizationURL)
            webView.load(request)
        }
    }
}
