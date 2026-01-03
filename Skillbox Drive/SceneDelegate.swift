import UIKit
import YandexLoginSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        print("hasSeenOnboarding: \(hasSeenOnboarding)")
        
        let rootViewController: UIViewController
        
        if hasSeenOnboarding {
            rootViewController = LoginViewController()
        } else {
            let model = OnboardingModel()
            let onboardingVC = OnboardingViewController()
            let presenter = OnboardingPresenter(view: onboardingVC, model: model)
            onboardingVC.presenter = presenter
            rootViewController = onboardingVC
        }
        
        window?.rootViewController = UINavigationController(rootViewController: rootViewController)
        window?.makeKeyAndVisible()
    }
    
    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        for urlContext in URLContexts {
            let url = urlContext.url
            
            do {
                try YandexLoginSDK.shared.handleOpenURL(url)
            } catch {
            }
        }
    }
}
