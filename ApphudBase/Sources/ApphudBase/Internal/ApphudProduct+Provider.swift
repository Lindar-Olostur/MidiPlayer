import ApphudSDK

extension ApphudProduct {
    var provider: ProductDataProvider {
        if let skProduct {
            SKProductDataProvider(skProduct: skProduct)
        } else {
            LocalStoreKitProductDataProvider(productId: productId)
        }
    }
}
