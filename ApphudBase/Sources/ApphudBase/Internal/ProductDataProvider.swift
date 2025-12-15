import Foundation

protocol ProductDataProvider {
    var price: Decimal { get }
    var priceLocale: Locale { get }
    var introductory: ProductDataIntroductory? { get }
    var subscriptionPeriod: ProductDataPeriod? { get }
}

extension ProductDataProvider {
    var isLifetime: Bool {
        subscriptionPeriod == nil
    }

    var isTrial: Bool {
        if case .freeTrial = introductory {
            return true
        } else {
            return false
        }
    }
    
    var isFree: Bool {
        price.isZero
    }
    
    var priceInDays: Decimal {
        firstPaymentPrice / Decimal((subscriptionPeriod ?? .init(unit: .year, numberOfUnits: 1)).days)
    }
    
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price as NSNumber)!
    }
    
    var localizedSubscriptionPeriod: String? {
        subscriptionPeriod?.format(omitOneUnit: true)
    }

    var localizedIntroductoryPeriod: String? {
        introductory?.period?.format(omitOneUnit: false)
    }

    var firstPaymentPrice: Decimal {
        introductory?.firstPaymentPrice ?? price
    }
    
    var firstPaymentLocalizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: firstPaymentPrice as NSNumber)!
    }
    
    func firstPaymentLocalizedPriceDivided(by divider: Decimal, maximumFractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter.string(from: (firstPaymentPrice / divider) as NSNumber)!
    }
    
    func extractDiscount(from provider: ProductDataProvider) -> Decimal {
        return 1 - priceInDays / provider.priceInDays
    }
    
    func extractDiscountLocalized(from provider: ProductDataProvider, maximumFractionDigits: Int) -> String {
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        percentFormatter.maximumFractionDigits = 0
        return percentFormatter.string(from: extractDiscount(from: provider) as NSNumber)!
    }
    
    func periodPrice(for targetPeriod: ProductDataPeriod) -> Decimal {
        priceInDays * Decimal(targetPeriod.days)
    }
    
    func localizedPeriodPrice(for targetPeriod: ProductDataPeriod, maximumFractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter.string(from: periodPrice(for: targetPeriod) as NSNumber)!
    }
}
