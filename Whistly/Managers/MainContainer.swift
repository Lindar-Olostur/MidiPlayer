
import Observation
import SwiftUI

@Observable
final class MainContainer {
    @MainActor var premium = PurchaseManager.shared
    var navigation = NavigationManager()
    var storage = TuneStoreManager()
    var sequencer = MIDISequencer()
    var userSettings = UserSettings()
    var authService = AuthService()
    var scrollManager = ScrollManager()
}

final class UserSettings {
    @AppStorage("defaultWhistleKey") var defaultWhistleKey: WhistleKey = .D
}
