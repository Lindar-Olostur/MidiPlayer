import Foundation
import ApphudSDK
import AdServices

extension Apphud {
    static let fallbackPaywalls: [ApphudPaywall] = {
        struct ApphudAPIDataResponse<T: Decodable>: Decodable {
            var data: T
        }
        struct ApphudAPIArrayResponse<T: Decodable>: Decodable {
            var results: [T]
        }

        typealias ApphudArrayResponse = ApphudAPIDataResponse<ApphudAPIArrayResponse <ApphudPaywall> >

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let response = try! decoder.decode(ApphudArrayResponse.self, from: Data(contentsOf: Bundle.main.url(forResource: "apphud_paywalls_fallback", withExtension: "json")!))
        let paywalls = response.data.results
        
        for paywall in paywalls {
            for product in paywall.products {
                product.setValue(paywall.identifier, forKey: "paywallIdentifier")
                product.setValue(Apphud.product(productIdentifier: product.productId), forKey: "skProduct")
            }
        }
        
        return paywalls
    }()
    
    static func setAttribution() {
        Task.detached {
            guard let token = try? AAAttribution.attributionToken() else { return }
            Apphud.setAttribution(data: nil, from: .appleAdsAttribution, identifer: token, callback: nil)
        }
    }
    
    static func performIntegrityCheck() {
        assert(Bundle.main.path(forResource: "apphud_paywalls_fallback", ofType: "json") != nil, "[ApphudBase] ❌ Missing required apphud_paywalls_fallback.json file.")
        
        do {
            try StoreKitCache.performCheck()
        } catch {
            assertionFailure("[ApphudBase] ❌ Cache check failed: \(error)")
        }
        
        var missingProducts: Set<String> = []
        for paywall in fallbackPaywalls {
            for product in paywall.products {
                if !StoreKitCache.has(productWithID: product.productId) {
                    missingProducts.insert(product.productId)
                }
            }
        }
        assert(missingProducts.isEmpty, "[ApphudBase] ❌ Missing products in StoreKit file: \(missingProducts.sorted())")
    }
}
