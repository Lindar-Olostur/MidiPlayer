import SwiftUI

extension LinearGradient {
    static var primary: LinearGradient {
        LinearGradient(
            colors: [.accentPrimary, .accentSecondary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

