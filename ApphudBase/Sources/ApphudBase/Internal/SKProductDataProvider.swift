import Foundation
import StoreKit

struct SKProductDataProvider: ProductDataProvider {
    private let skProduct: SKProduct
    init(skProduct: SKProduct) {
        self.skProduct = skProduct
    }
    
    var price: Decimal {
        skProduct.price.decimalValue
    }
    
    var priceLocale: Locale {
        skProduct.priceLocale
    }
    
    var subscriptionPeriod: ProductDataPeriod? {
        skProduct.subscriptionPeriod.map { period in
            ProductDataPeriod(unit: period.unit.toCalendarUnit(), numberOfUnits: period.numberOfUnits)
        }
    }
    
    var introductory: ProductDataIntroductory? {
        skProduct.introductoryPrice.map { introductory in
            let period = ProductDataPeriod(unit: introductory.subscriptionPeriod.unit.toCalendarUnit(), numberOfUnits: introductory.subscriptionPeriod.numberOfUnits)
            switch introductory.paymentMode {
            case .freeTrial: return .freeTrial(period)
            case .payUpFront: return .payUpFront(introductory.price.decimalValue, period)
            case .payAsYouGo: return .payAsYouGo(introductory.price.decimalValue, period, introductory.numberOfPeriods)
            }
        }
    }
}

private extension SKProduct.PeriodUnit {
    func toCalendarUnit() -> NSCalendar.Unit {
        switch self {
        case .day:
            return .day
        case .month:
            return .month
        case .week:
            return .weekOfMonth
        case .year:
            return .year
        @unknown default:
            assertionFailure("Unknown period unit")
        }
        return .day
    }
}
