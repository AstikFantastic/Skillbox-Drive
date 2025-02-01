import UIKit

protocol ProfileView: AnyObject {
    func showDiskData(_ diskData: ProfileModel)
    func showError(_ error: Error)
}

class ProfilePresenter {
    
    weak var view: ProfileView?
    private let apiService: APIService
    private let oAuthToken: String
    
    init(view: ProfileView, oAuthToken: String, apiService: APIService = .shared) {
        self.view = view
        self.oAuthToken = oAuthToken
        self.apiService = apiService
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
}
