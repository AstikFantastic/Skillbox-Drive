import UIKit

protocol LoginRouterProtocol {
    func navigateToTabBar(from view: UIViewController)
}

class LoginRouter: LoginRouterProtocol {
    func navigateToTabBar(from view: UIViewController) {
        
        let tabBarController = UITabBarController()
        
        let firstViewController = ProfileViewController()
        firstViewController.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(named: "Person"), tag: 0)
        
        let secondViewController = LastFilesViewController()
        secondViewController.tabBarItem = UITabBarItem(title: "Last", image: UIImage(named: "Last"), tag: 1)
        
        let thirdViewController = AllFilesViewController()
        thirdViewController.tabBarItem = UITabBarItem(title: "All files", image: UIImage(named: "All Files"), tag: 2)
        
        tabBarController.viewControllers = [firstViewController, secondViewController, thirdViewController]
        
        view.navigationController?.pushViewController(tabBarController, animated: true)
    }
    

}
