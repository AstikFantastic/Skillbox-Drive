//
//  SceneDelegate.swift
//  Skillbox Drive
//
//  Created by Астимир Марышев on 12/7/24.
//

import UIKit
import YandexLoginSDK



class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        print("hasSeenOnboarding: \(hasSeenOnboarding)") // Посмотреть в консоли
        
        if hasSeenOnboarding {
            // Пропустите онбординг, если он уже был просмотрен
            let mainVC = LoginViewController()
            window?.rootViewController = UINavigationController(rootViewController: mainVC)
        } else {
            // Иначе показываем онбординг
            let model = OnboardingModel()
            let onboardingVC = OnboardingViewController()
            let presenter = OnboardingPresenter(view: onboardingVC, model: model)
            onboardingVC.presenter = presenter
            
            window?.rootViewController = UINavigationController(rootViewController: onboardingVC)
        }
        window?.makeKeyAndVisible()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        URLContexts.forEach { context in
            if YandexLoginSDK.shared.isURLRelatedToSDK(url: context.url) {
                do {
                    try YandexLoginSDK.shared.handleOpenURL(context.url)
                } catch {
                    // Обработка ошибки, если она возникает
                    print("Ошибка при обработке URL: \(error)")
                }
            }
        }
}

func sceneDidDisconnect(_ scene: UIScene) {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}

func sceneDidBecomeActive(_ scene: UIScene) {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}

func sceneWillResignActive(_ scene: UIScene) {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}

func sceneWillEnterForeground(_ scene: UIScene) {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}

func sceneDidEnterBackground(_ scene: UIScene) {
    UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
    
    (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
}


}

