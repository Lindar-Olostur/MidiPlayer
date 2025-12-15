import Foundation
import ApphudSDK
import StoreKit

extension ApphudProduct: @retroactive Identifiable {}

public extension ApphudProduct {
    var isLifetime: Bool { provider.isLifetime }
    var isTrial: Bool { provider.isTrial }
    var isFree: Bool { provider.isFree }
    
    var price: Decimal { provider.price }
    var priceLocale: Locale { provider.priceLocale }
    var localizedPrice: String { provider.localizedPrice }
    
    var introductory: ProductDataIntroductory? { provider.introductory }
    var localizedIntroductoryPeriod: String? { provider.localizedIntroductoryPeriod }
    
    var firstPaymentPrice: Decimal { provider.firstPaymentPrice }
    var firstPaymentLocalizedPrice: String { provider.firstPaymentLocalizedPrice }
    func firstPaymentLocalizedPriceDivided(by divider: Decimal, maximumFractionDigits: Int = 2) -> String { provider.firstPaymentLocalizedPriceDivided(by: divider, maximumFractionDigits: maximumFractionDigits) }
    
    var subscriptionPeriod: ProductDataPeriod? { provider.subscriptionPeriod }
    var localizedSubscriptionPeriod: String? { provider.localizedSubscriptionPeriod }
    
    func extractDiscount(from product: ApphudProduct) -> Decimal { provider.extractDiscount(from: product.provider) }
    func extractDiscountLocalized(from product: ApphudProduct, maximumFractionDigits: Int = 0) -> String { provider.extractDiscountLocalized(from: product.provider, maximumFractionDigits: maximumFractionDigits) }
    
    func periodPrice(for targetPeriod: ProductDataPeriod) -> Decimal { provider.periodPrice(for: targetPeriod) }
    func localizedPeriodPrice(for targetPeriod: ProductDataPeriod, maximumFractionDigits: Int = 2) -> String { provider.localizedPeriodPrice(for: targetPeriod, maximumFractionDigits: maximumFractionDigits) }
}
