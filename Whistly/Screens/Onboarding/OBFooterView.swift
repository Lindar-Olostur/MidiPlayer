import SwiftUI

struct OBFooterView: View {
    @EnvironmentObject var premium: PurchaseManager
    @EnvironmentObject var router: NavigationManager
    @Environment(\.openURL) var openURL
    @Binding var isRestoring: Bool
    let color: Color = .textSecondary
    
    var body: some View {
        HStack(spacing: 0) {
            Button {
                openURL(URL(string: termsOfUse)!)
            } label: {
                Text("Terms of Use")
                    .font(.footnote)
                    .foregroundStyle(color)
                    .fixedSize()
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
            }
            Button {
                isRestoring = true
                premium.restorePurchase { success in
                    isRestoring = false
                    if success {
                    }
                }
            } label: {
                Text("Restore")
                    .font(.footnote)
                    .foregroundStyle(color)
                    .fixedSize()
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
            }
            Button {
                openURL(URL(string: privacyPolicy)!)
            } label: {
                Text("Privacy Policy")
                    .font(.footnote)
                    .foregroundStyle(color)
                    .fixedSize()
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
            }
        }
    }
}

#Preview {
    OBFooterView(isRestoring: .constant(false))
        .environmentObject(PurchaseManager.shared)
        .environmentObject(NavigationManager())
}

