import Foundation

struct OnboardingPage {
    let onboardingImage: String
    let description: String
}

class OnboardingModel {
    var pages: [OnboardingPage] = [OnboardingPage(onboardingImage: "FirstOnboarding", description: "Теперь все ваши документы на месте"),
        OnboardingPage(onboardingImage: "SecondOnboarding", description: "Доступ к файлам без интернета"),
        OnboardingPage(onboardingImage: "ThirdOnboarding", description: "Делитесь вашими файлами с другими")
    ]
    
    var currentIndex: Int = 0
}
