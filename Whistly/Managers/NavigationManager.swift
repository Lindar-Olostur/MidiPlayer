import SwiftUI
import Observation

@Observable
final class NavigationManager {
    @MainActor let premium = PurchaseManager.shared
    var screen: Screen = .splash
    var onCompleted: Bool {
            get {
                UserDefaults.standard.bool(forKey: "onboardingKey")
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "onboardingKey")
            }
        }
    var openMainPaywall: Bool = false
   
    @MainActor func splashFinished() {
        if onCompleted {
            if premium.isSubscribed {
                withAnimation { screen = .main }
            } else {
                withAnimation { screen = .paywall }
            }
        } else {
            withAnimation { screen = .onboarding }
        }
    }
    
    @MainActor func onboardingFinished() {
        onCompleted = true
        if premium.isSubscribed {
            withAnimation { screen = .main }
        } else {
            withAnimation { screen = .paywall }
        }
    }
    
    @MainActor func goToScreen(_ screen: Screen) {
        withAnimation { self.screen = screen }
    }
}

enum Screen: Equatable {
    case splash, onboarding, paywall, main
}


