import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct WhistlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State var viewModel = MainContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            .environment(viewModel)
        }
    }
}
