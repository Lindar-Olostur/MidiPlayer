import StoreKit
import ApphudSDK
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var router: NavigationManager
    @EnvironmentObject var premium: PurchaseManager
    @Environment(\.dismiss) var dismiss
    @State var isTrial = false
    @State var isPurchasing = false
    @State var currentProduct: ProductType = .weekNonTrial
    let isOB: Bool
    
    var body: some View {
        VStack(alignment: UIDevice.isIPad ? .center : .leading, spacing: 6) {
            Spacer()
            VStack(alignment: .center, spacing: 8) {
                Group {
                    Text("Get Premium")
                        .font(.title)
                        .padding(.vertical, 8)
                    VStack(alignment: .center, spacing: 4) {
                        PWFeatureView(text: "Learning without limits")
                        PWFeatureView(text: "Import as many files as you want.")
                        PWFeatureView(text: "Get access to training mode.")
                    }
                    .padding(.leading, UIScreen.main.bounds.width / 2 * 0.2)
                    .frame(width: UIScreen.main.bounds.width - 64)
                    .roundCard(padding: 16, color: .fillQuartenary, radius: 16)
                    VStack(spacing: 2) {
                        Text("Subscribe to unlock all the features\nfor just \(premium.product(for: currentProduct)!.fullPrice)")
                            .font(.body)
                        Button {
                            if isOB {
                                router.goToScreen(.main)
                            } else {
                                dismiss()
                            }
                        } label: {
                            Text("or proceed with limits")
                                .font(.body)
                                .foregroundStyle(.textSecondary)
                        }
                        .disabled(isPurchasing)
                    }
                    .padding(.vertical, 8)
                }
                .multilineTextAlignment(.center)
                .fixedSize()
                if currentProduct != .lifetime {
                    PurchasesToggle(toggle: $isTrial, tintColor: .blue, bgColor: .fillQuartenary, scale: 1, textColor: .textPrimary, offColor: .bgPrimary, text: isTrial ? "3 days free trial enabled" : "Enable a 3 days free trial", corners: 73, height: 56, width: .infinity)
                        .disabled(isPurchasing)
                }
                BigButton() {
                    purchasing()
                } label: {
                    Text(isPurchasing ? "Loading..." : "Continue")
                        .font(.body)
                        .foregroundStyle(.textPrimary)
                }
                .padding(.vertical, 8)
                .disabled(isPurchasing)
                OBFooterView(isRestoring: $isPurchasing)
                    .disabled(isPurchasing)
            }
            .padding(16)
            .frame(maxWidth: !UIDevice.isIPad ? .infinity : 375)
            .background(.fillQuartenary)
            .clipShape(RoundedCorner(radius: 26, corners: [.topLeft, .topRight]))
        }
        .background {
            BackgroundView()
//            if UIDevice.isIPad { TODO
//                Image(".pwl")
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//            } else {
//                Image(".pws")
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//            }
        }
        .ignoresSafeArea()
        .onAppear {
            Apphud.paywallShown(premium.product(for: currentProduct))
            
            if currentProduct == .weekTrial {
                isTrial = true
            } else {
                isTrial = false
            }
        }
        .onDisappear {
            Apphud.paywallClosed(premium.product(for: currentProduct))
        }
        .onChange(of: isTrial) { value in
            currentProduct = value ? .weekTrial : .weekNonTrial
        }
    }
    
    func purchasing() {
        guard let currentProduct = premium.product(for: currentProduct) else { return }
        isPurchasing = true
        premium.makePurchase(product: currentProduct) { success in
            DispatchQueue.main.async {
                if success {
                    if isOB {
                        router.goToScreen(.main)
                    } else {
                        dismiss()
                    }
                }
                isPurchasing = false
            }
        }
    }
}

#Preview {
    PaywallView(currentProduct: .weekTrial, isOB: false)
        .environmentObject(NavigationManager())
        .environmentObject(PurchaseManager.shared)
        .delayedAppearance(delay: 2.0)
}

