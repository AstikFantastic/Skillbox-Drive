import UIKit

class OnboardingPresenter {
    private weak var view: OnboardingView?
    private let model: OnboardingModel
    
    init(view: OnboardingView? = nil, model: OnboardingModel) {
        self.view = view
        self.model = model
    }
    
    func viewDidLoad() {
        updateView()
    }
    
    func didTapNext() {
        if model.currentIndex < model.pages.count - 1 {
            model.currentIndex += 1
            updateView()
        } else {
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
            UserDefaults.standard.synchronize()
            view?.navigateToNextScreen()
        }
    }

   
    private func updateView() {
        let page = model.pages[model.currentIndex]
        guard let image = UIImage(named: page.onboardingImage) else { return }
        view?.displayPage(image: image, description: page.description, currentIndex: model.currentIndex, totalPages: model.pages.count)
    }
}
