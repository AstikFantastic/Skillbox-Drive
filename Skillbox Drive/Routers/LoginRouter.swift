import UIKit

protocol LoginRouterProtocol {
    func navigateToTabBar(from view: UIViewController)
}

class LoginRouter: LoginRouterProtocol {
    func navigateToTabBar(from view: UIViewController) {
        let tabBarController = UITabBarController()

        let profileVC = ProfileViewController()
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(named: "Person"), tag: 0)

        let lastFilesVC = LastFilesViewController()
        let lastFilesNav = UINavigationController(rootViewController: lastFilesVC)
        lastFilesNav.tabBarItem = UITabBarItem(title: "Last", image: UIImage(named: "Last"), tag: 1)

        let allFilesVC = AllFilesViewController()
        let allFilesNav = UINavigationController(rootViewController: allFilesVC)
        allFilesNav.tabBarItem = UITabBarItem(title: "All files", image: UIImage(named: "All Files"), tag: 2)

        tabBarController.viewControllers = [profileNav, lastFilesNav, allFilesNav]
        
        if let window = view.view.window {
            window.rootViewController = tabBarController
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        } else {
            view.navigationController?.setViewControllers([tabBarController], animated: true)
        }
    }
}
