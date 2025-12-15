import SwiftUI
import StoreKit

struct ContentView: View {
    @EnvironmentObject var premium: PurchaseManager
    @EnvironmentObject var navigation: NavigationManager
    @AppStorage("mustShowInstruction") private var mustShowInstruction = true
    @AppStorage("shouldShowRateAlert") private var shouldShowRateAlert = true
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch navigation.screen {
                case .splash: SplashView()
                case .onboarding: OnboardingView()
                case .onboardingPaywall: PaywallView(isOB: true)
                case .main: EmptyView()
                        .onAppear {
                            Task { @MainActor in
                                mustShowInstruction = false
                                if shouldShowRateAlert {
                                    if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                                        AppStore.requestReview(in: scene)
                                        shouldShowRateAlert = false
                                    }
                                }
                            }
                        }
                }
            }
            .transition(.opacity)
//            .alert("Photos Access Needed", isPresented: $permissions.showPhotoPermissionAlert) {
//                Button("Cancel") { permissions.showPhotoPermissionAlert = false }
//                Button("Settings") {
//                    permissions.openSettings()
//                }
//                .keyboardShortcut(.defaultAction)
//            } message: {
//                Text("Access is required to import and compress your files. Please allow access in Settings")
//            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PurchaseManager.shared)
        .environmentObject(NavigationManager())
}

