import SwiftUI

@main
struct WhistlyApp: App {
    @StateObject var premium = PurchaseManager.shared
    @StateObject var navigation = NavigationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            .environmentObject(navigation)
            .environmentObject(premium)
        }
    }
}
