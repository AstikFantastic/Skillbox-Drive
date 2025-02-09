import UIKit
import YandexLoginSDK

protocol ProfilePresenterProtocol: AnyObject {
    func fetchDiskData()
    func didTapMoreButton()
    func logout()
    func formatBtToGb(_ bytes: Int64) -> String
    func findAvailableSpace(diskData: ProfileModel) -> String
}


class ProfilePresenter {
    
    weak var view: ProfileViewProtocol?
    private let apiService: APIService
    private let oAuthToken: String
    private let router: Router
    
    init(view: ProfileViewProtocol, oAuthToken: String, apiService: APIService = .shared, router: Router) {
        self.view = view
        self.oAuthToken = oAuthToken
        self.apiService = apiService
        self.router = router
    }
    
    func fetchDiskData() {
        apiService.fetchDiskData(oAuthToken: oAuthToken) { [weak self] result in
            switch result {
            case .success(let diskData):
                self?.view?.showDiskData(diskData)
            case .failure(let error):
                self?.view?.showError(error)
            }
        }
    }
    
    func calculateUsedPercentage(diskData: ProfileModel) -> CGFloat {
        return CGFloat(diskData.usedSpace) / CGFloat(diskData.totalSpace)
    }
    
    func formatBtToGb(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", gb)
        } else {
            return String(format: "%.2f", gb)
        }
    }
    
    func findAvailableSpace(diskData: ProfileModel) -> String {
        return formatBtToGb(Int64(diskData.totalSpace) - Int64(diskData.usedSpace))
    }
    
    func didTapMoreButton() {
        view?.showLogoutConfirmation()
    }
    
    func logout() {
        do {
            UserDefaults.standard.removeObject(forKey: "userToken")
            try YandexLoginSDK.shared.logout()
        } catch {
            print("Ошибка выхода: \(error.localizedDescription)")
        }
        router.navigateToLoginScreen()
    }
}

