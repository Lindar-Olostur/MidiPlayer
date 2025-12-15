import SwiftUI

struct BackgroundView: View {
    var body: some View {
        Color.bgPrimary.ignoresSafeArea()
            .overlay {
                Circle()
                    .fill(.accentPrimary)
                    .padding(32)
                    .blur(radius: 130)
                    .opacity(0.45)
                Color.black.opacity(0.1)
            }
    }
}

#Preview {
    BackgroundView()
}
