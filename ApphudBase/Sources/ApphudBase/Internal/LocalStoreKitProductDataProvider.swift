import Foundation

internal struct LocalStoreKitProductDataProvider: ProductDataProvider {
    private let localProduct: StoreKitContent.Product
    
    init(productId: String) {
        guard let product = StoreKitCache.productsById[productId] else {
            fatalError("[ApphudBase] Product with id \(productId) not found in .storekit file")
        }
        self.localProduct = product
    }
    
    var price: Decimal {
        Decimal(string: localProduct.displayPrice, locale: priceLocale)!
    }
    
    var priceLocale: Locale {
        Locale(identifier: "en_US")
    }
    
    var subscriptionPeriod: ProductDataPeriod? {
        localProduct.recurringSubscriptionPeriod.map { period in
            ProductDataPeriod(unit: period.unit, numberOfUnits: period.numberOfUnits)
        }
    }
    
    var introductory: ProductDataIntroductory? {
        localProduct.introductoryOffer.map { introductory in
            let period = ProductDataPeriod(unit: introductory.subscriptionPeriod.unit, numberOfUnits: introductory.subscriptionPeriod.numberOfUnits)
            switch introductory.paymentMode {
            case .free: return .freeTrial(period)
            case .payUpFront: return .payUpFront(Decimal(string: introductory.displayPrice!, locale: priceLocale)!, period)
            case .payAsYouGo: return .payAsYouGo(Decimal(string: introductory.displayPrice!, locale: priceLocale)!, period, introductory.numberOfPeriods!)
            }
        }
    }
}
