import Foundation

enum StoreKitCache {
    enum Error: Swift.Error {
        case fileNotFound
        case hasDuplicatingIds
    }
    
    static func performCheck() throws {
        guard let url = Bundle.main.url(forResource: nil, withExtension: "storekit") else {
            throw Error.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let content = try JSONDecoder().decode(StoreKitContent.self, from: data)
        let ids = content.products.map(\.productID)
        if Set(ids).count != ids.count {
            throw Error.hasDuplicatingIds
        }
    }
    
}

extension StoreKitCache {
    static func has(productWithID id: String) -> Bool {
        productsById.keys.contains(id)
    }
    static let productsById: [String: StoreKitContent.Product] = {
        let url = Bundle.main.url(forResource: nil, withExtension: "storekit")!
        let data = try! Data(contentsOf: url)
        let content = try! JSONDecoder().decode(StoreKitContent.self, from: data)
        return Dictionary(uniqueKeysWithValues: content.products.map { ($0.productID, $0) })
    }()
}
